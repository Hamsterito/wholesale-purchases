import '../models/product.dart';

Product getSampleProduct() {
  return Product(
    id: '1',
    name: 'Напиток Coca-Cola газированный 1.5 л',
    description:
        'Coca-Cola — самый популярный газированный напиток в мире. Имеет резкий, но приятный вкус, хорошо утоляет жажду, рекомендуется пить охлажденным.',
    imageUrls: ['assets/coca_cola.jpeg'],
    rating: 4.7,
    reviewCount: 13,
    categories: ['Напитки', 'Газированные напитки'],
    nutritionalInfo: NutritionalInfo(
      calories: 42,
      protein: 0,
      fat: 0,
      carbohydrates: 10.6,
    ),
    ingredients:
        'Газированная вода, сахар, краситель (сахарный колер [IV]), регулятор кислотности (ортофосфорная кислота), натуральные ароматизаторы, кофеин.',
    characteristics: {
      'Страна производителя': 'Казахстан',
      'Торговая марка': 'Coca-Cola',
      'Линейка': 'Классическая',
    },
    suppliers: [
      Supplier(
        id: '1',
        name: 'Склад "Манса"',
        rating: 5.0,
        reviewCount: 131,
        pricePerUnit: 790,
        minQuantity: 5,
        deliveryDate: 'завтра',
        deliveryInfo: 'Доставка межгород',
        deliveryBadge: 'Четверг 17:00',
      ),
      Supplier(
        id: '2',
        name: 'Gruz.kz',
        rating: 4.9,
        reviewCount: 131,
        pricePerUnit: 800,
        minQuantity: 4,
        deliveryDate: 'Вс 21 сентября',
        deliveryInfo: 'Доставка межгород',
        deliveryBadge: 'Сб 23 сентября 12:00',
      ),
      Supplier(
        id: '3',
        name: 'Какой-то крутой поставщик',
        rating: 4.9,
        reviewCount: 131,
        pricePerUnit: 810,
        minQuantity: 6,
        deliveryDate: 'Сб 20 сентября',
        deliveryInfo: 'Доставка межгород',
        deliveryBadge: 'Четверг 17:00',
      ),
    ],
    similarProducts: [],
    ratingDistribution: [
      RatingDistribution(stars: 5, count: 7),
      RatingDistribution(stars: 4, count: 3),
      RatingDistribution(stars: 3, count: 1),
      RatingDistribution(stars: 2, count: 1),
      RatingDistribution(stars: 1, count: 1),
    ],
  );
}

List<Product> getSampleProducts() {
  return List.generate(10, (index) => getSampleProduct());
}
