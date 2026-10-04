enum ItemType { potion, key, misc }

class Item {
  const Item(this.id, this.name, this.icon, this.type, [this.value = 0]);
  final String id, name, icon;
  final ItemType type;
  final int value; // heal amount for potions
}

class Items {
  static const all = <String, Item>{
    'potion': Item('potion', 'Health Potion', 'potion.png', ItemType.potion, 30),
    'key': Item('key', 'Old Key', 'key.png', ItemType.key),
  };
}
