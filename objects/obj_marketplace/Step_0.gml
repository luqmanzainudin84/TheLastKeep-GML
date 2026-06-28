// Copy Code - obj_marketplace (Step Event)

// Fungsi untuk transaksi jual beli
function process_purchase(_hero, _item_type) {
    var _price = 50; // Contoh harga item
    
    if (global.gold >= _price) {
        // 1. Kurangkan duit kerajaan atau hero
        global.gold -= _price;
        
        // 2. Tambah item ke slot spare hero
        var _new_item = { name: _item_type, atk: 10, durability: 100 };
        array_push(_hero.spare_weapons, _new_item);
        
        show_debug_message(_hero.name + " telah membeli " + _item_type);
    }
}