// ============================================================
// scr_map_generator
// Procedural grid map generator untuk The Last Keep
// ============================================================

// ------------------------------------------------------------
// MAP CONSTANTS
// ------------------------------------------------------------
function map_get_config() {
    return {
        cols      : 64,         // bilangan cell horizontal
        rows      : 64,         // bilangan cell vertical
        cell_size : 32,         // pixel per cell

        // Noise settings
        noise_scale  : 0.08,    // makin kecil = terrain lebih smooth
        noise_seed   : 0,       // akan di-randomize semasa generate

        // Kingdom start zone
        start_col    : 32,
        start_row    : 32,
        start_radius : 5,       // cells dalam radius start = clear grass

        // Terrain thresholds (noise value)
        threshold_water    : 0.20,
        threshold_grass    : 0.45,
        threshold_forest   : 0.68,
        // mountain = everything above forest threshold

        // Resource spawn chances (pada terrain yang sesuai)
        chance_wood_node   : 0.15,  // 15% forest cell ada kayu
        chance_stone_node  : 0.20,  // 20% mountain cell ada batu
        chance_iron_node   : 0.08,  // 8% mountain cell ada besi
        chance_ruins       : 0.05,  // 5% grass cell ada ruins
    };
}

// ------------------------------------------------------------
// TERRAIN CONSTANTS
// ------------------------------------------------------------
function map_get_terrain_types() {
    return {
        WATER    : 0,
        GRASS    : 1,
        FOREST   : 2,
        MOUNTAIN : 3,
        RUINS    : 4,
    };
}

// ------------------------------------------------------------
// VISIBILITY CONSTANTS
// ------------------------------------------------------------
function map_get_visibility_types() {
    return {
        HIDDEN   : 0,
        EXPLORED : 1,
        VISIBLE  : 2,
    };
}

// ------------------------------------------------------------
// BUAT SATU CELL
// ------------------------------------------------------------
function map_create_cell(_col, _row, _terrain) {
    return {
        col      : _col,
        row      : _row,
        terrain  : _terrain,
        walkable : (_terrain != map_get_terrain_types().WATER
                 && _terrain != map_get_terrain_types().MOUNTAIN),
        visibility : map_get_visibility_types().HIDDEN,

        // Resource node (undefined kalau tiada)
        resource : undefined,

        // Building reference (noone kalau tiada)
        building : noone,
    };
}

// ------------------------------------------------------------
// RESOURCE NODE FACTORY
// ------------------------------------------------------------
function map_create_resource_node(_type, _amount, _regen) {
    return {
        type       : _type,     // "wood", "stone", "iron", dll
        amount     : _amount,
        amount_max : _amount,
        regen_rate : _regen,    // amount per game day
        regen_acc  : 0,

        // Harvest dari node — dipanggil oleh hero Gatherer/Miner
        harvest : function(_harvest_amount = 5) {
            var _actual = min(_harvest_amount, amount);
            amount -= _actual;
            return _actual;
        },

        // Tick regen — dipanggil setiap game day
        tick_regen : function() {
            if (amount >= amount_max) return;
            regen_acc += regen_rate;
            if (regen_acc >= 1) {
                var _whole  = floor(regen_acc);
                amount     += _whole;
                regen_acc  -= _whole;
                amount      = min(amount, amount_max);
            }
        },

        is_depleted : function() { return amount <= 0; },
    };
}

// ------------------------------------------------------------
// MAIN GENERATOR
// ------------------------------------------------------------
function map_generate(_config) {
    var _cfg     = _config;
    var _terrain = map_get_terrain_types();
    var _vis     = map_get_visibility_types();

    // Randomize noise seed
    _cfg.noise_seed = irandom(99999);

    // Buat 2D array grid
    // grid[col][row] = cell struct
    var _grid = array_create(_cfg.cols);
    for (var c = 0; c < _cfg.cols; c++) {
        _grid[c] = array_create(_cfg.rows);
    }

    // --- PASS 1: Generate terrain dari noise ---
    for (var c = 0; c < _cfg.cols; c++) {
        for (var r = 0; r < _cfg.rows; r++) {

            // Semak sama ada dalam start zone
            var _dist_from_start = point_distance(c, r,
                _cfg.start_col, _cfg.start_row);
            var _in_start_zone   = (_dist_from_start <= _cfg.start_radius);

            var _terrain_type;

            if (_in_start_zone) {
                // Start zone sentiasa Grass — selamat untuk kingdom
                _terrain_type = _terrain.GRASS;
            } else {
                // Guna noise untuk terrain
				var _nx    = (c + _cfg.noise_seed) * _cfg.noise_scale;
				var _ny    = (r + _cfg.noise_seed) * _cfg.noise_scale;
				var _value = (
				    sin(_nx * 1.7 + _ny * 0.9) * 0.3 +
				    sin(_nx * 0.5 - _ny * 1.3) * 0.3 +
				    sin(_nx * 2.3 + _ny * 2.1) * 0.2 +
				    cos(_nx * 0.8 + _ny * 1.7) * 0.2
				    + 1.0) / 2.0;

                if (_value <= _cfg.threshold_water) {
                    _terrain_type = _terrain.WATER;
                } else if (_value <= _cfg.threshold_grass) {
                    _terrain_type = _terrain.GRASS;
                } else if (_value <= _cfg.threshold_forest) {
                    _terrain_type = _terrain.FOREST;
                } else {
                    _terrain_type = _terrain.MOUNTAIN;
                }
            }

            _grid[c][r] = map_create_cell(c, r, _terrain_type);
        }
    }

    // --- PASS 2: Spawn resource nodes ---
    for (var c = 0; c < _cfg.cols; c++) {
        for (var r = 0; r < _cfg.rows; r++) {
            var _cell = _grid[c][r];

            switch (_cell.terrain) {
                case _terrain.FOREST:
                    if (random(1) < _cfg.chance_wood_node) {
                        _cell.resource = map_create_resource_node(
                            "wood",
                            irandom_range(50, 150),  // amount
                            0.5                       // regen per day
                        );
                    }
                break;

                case _terrain.MOUNTAIN:
                    if (random(1) < _cfg.chance_stone_node) {
                        _cell.resource = map_create_resource_node(
                            "stone",
                            irandom_range(30, 100),
                            0.2
                        );
                    } else if (random(1) < _cfg.chance_iron_node) {
                        _cell.resource = map_create_resource_node(
                            "iron",
                            irandom_range(15, 50),
                            0.1
                        );
                    }
                break;

                case _terrain.GRASS:
                    // Ruins spawn pada grass
                    var _dist_from_start = point_distance(c, r,
                        _cfg.start_col, _cfg.start_row);
                    if (_dist_from_start > _cfg.start_radius + 3
                    &&  random(1) < _cfg.chance_ruins) {
                        _cell.terrain  = _terrain.RUINS;
                        _cell.walkable = true;
                        // TODO: ruins akan ada enemy spawn + loot
                    }
                break;
            }
        }
    }

    // --- PASS 3: Start zone visibility ---
    // Kingdom start area terus VISIBLE
    for (var c = 0; c < _cfg.cols; c++) {
        for (var r = 0; r < _cfg.rows; r++) {
            var _dist = point_distance(c, r,
                _cfg.start_col, _cfg.start_row);
            if (_dist <= _cfg.start_radius) {
                _grid[c][r].visibility = _vis.VISIBLE;
            }
        }
    }

    return _grid;
}

// ------------------------------------------------------------
// UTILITY FUNCTIONS — digunakan oleh sistem lain
// ------------------------------------------------------------

// Tukar world position (pixel) ke grid cell
function map_world_to_cell(_wx, _wy, _config) {
    return {
        col : floor(_wx / _config.cell_size),
        row : floor(_wy / _config.cell_size),
    };
}

// Tukar grid cell ke world position (pixel) — center of cell
function map_cell_to_world(_col, _row, _config) {
    return {
        x : (_col * _config.cell_size) + (_config.cell_size / 2),
        y : (_row * _config.cell_size) + (_config.cell_size / 2),
    };
}

// Semak sama ada cell valid (dalam boundary)
function map_is_valid_cell(_col, _row, _config) {
    return (_col >= 0 && _col < _config.cols
         && _row >= 0 && _row < _config.rows);
}

// Dapatkan cell dari grid dengan selamat
function map_get_cell(_grid, _col, _row, _config) {
    if (!map_is_valid_cell(_col, _row, _config)) return undefined;
    return _grid[_col][_row];
}

// Dapatkan semua cell jiran (4-directional)
function map_get_neighbours(_grid, _col, _row, _config) {
    var _neighbours = [];
    var _dirs = [
        {dc:  0, dr: -1},   // atas
        {dc:  0, dr:  1},   // bawah
        {dc: -1, dr:  0},   // kiri
        {dc:  1, dr:  0},   // kanan
    ];

    for (var i = 0; i < array_length(_dirs); i++) {
        var _nc = _col + _dirs[i].dc;
        var _nr = _row + _dirs[i].dr;
        var _cell = map_get_cell(_grid, _nc, _nr, _config);
        if (!is_undefined(_cell)) {
            array_push(_neighbours, _cell);
        }
    }
    return _neighbours;
}