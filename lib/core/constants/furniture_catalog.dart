/// Furniture that can be placed in the room planner, with default sizes in
/// feet (converted to the room's unit when added).
library;

enum FurnitureShape { rect, circle, rug }

enum FurnitureType {
  bed('Bed', 5, 6.7, FurnitureShape.rect),
  sofa('Sofa', 6, 3, FurnitureShape.rect),
  table('Table', 3, 2.5, FurnitureShape.rect),
  chair('Chair', 1.6, 1.6, FurnitureShape.rect),
  wardrobe('Wardrobe', 4, 2, FurnitureShape.rect),
  tv('TV', 4, 0.8, FurnitureShape.rect),
  plant('Plant', 1.2, 1.2, FurnitureShape.circle),
  storage('Storage', 3, 1.5, FurnitureShape.rect),
  desk('Desk', 4, 2, FurnitureShape.rect),
  bookshelf('Bookshelf', 3, 1.2, FurnitureShape.rect),
  rug('Rug', 4, 6, FurnitureShape.rug),
  lamp('Floor lamp', 0.9, 0.9, FurnitureShape.circle),
  mirror('Mirror', 2.5, 0.3, FurnitureShape.rect);

  const FurnitureType(this.label, this.widthFt, this.depthFt, this.shape);

  final String label;
  final double widthFt;
  final double depthFt;
  final FurnitureShape shape;

  static FurnitureType fromName(String value) =>
      FurnitureType.values.firstWhere((t) => t.name == value, orElse: () => FurnitureType.storage);
}

enum MeasurementUnit {
  ft('ft', 1),
  m('m', 0.3048);

  const MeasurementUnit(this.label, this.perFoot);

  final String label;

  /// How many of this unit make one foot.
  final double perFoot;

  static MeasurementUnit fromName(String value) =>
      MeasurementUnit.values.firstWhere((u) => u.name == value, orElse: () => MeasurementUnit.ft);
}
