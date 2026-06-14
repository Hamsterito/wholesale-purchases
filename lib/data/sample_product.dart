import 'package:flutter_project/services/localization/app_localizations.dart';
import '../models/product.dart';

Product getSampleProduct() {
  return Product(
    id: '1',
    name: AppLocalizations.current.getString('auto_napitok_cocacola_gazirovannyy_15_l'),
    description:
        AppLocalizations.current.getString('auto_cocacola_samyy_populyarnyy_gazirova'),
    imageUrls: ['assets/coca_cola.jpeg'],
    rating: 4.7,
    reviewCount: 13,
    questionCount: 5,
    categories: [AppLocalizations.current.getString('auto_napitki'), AppLocalizations.current.getString('auto_gazirovannye_napitki')],
    nutritionalInfo: NutritionalInfo(
      calories: 42,
      protein: 0,
      fat: 0,
      carbohydrates: 10.6,
    ),
    ingredients:
        AppLocalizations.current.getString('auto_gazirovannaya_voda_sahar_krasitel_s'),
    characteristics: {
      AppLocalizations.current.getString('auto_strana_proizvoditelya'): AppLocalizations.current.getString('auto_kazahstan'),
      AppLocalizations.current.getString('auto_torgovaya_marka'): 'Coca-Cola',
      AppLocalizations.current.getString('auto_lineyka'): AppLocalizations.current.getString('auto_klassicheskaya'),
    },
    suppliers: [
      Supplier(
        id: '1',
        name: AppLocalizations.current.getString('auto_sklad_mansa'),
        rating: 5.0,
        reviewCount: 131,
        pricePerUnit: 790,
        minQuantity: 5,
        stockQuantity: 120,
        deliveryDate: AppLocalizations.current.getString('auto_zavtra'),
        deliveryInfo: AppLocalizations.current.getString('auto_dostavka_mezhgorod'),
        deliveryBadge: AppLocalizations.current.getString('auto_chetverg_1700'),
      ),
      Supplier(
        id: '2',
        name: 'Gruz.kz',
        rating: 4.9,
        reviewCount: 131,
        pricePerUnit: 800,
        minQuantity: 4,
        stockQuantity: 90,
        deliveryDate: AppLocalizations.current.getString('auto_vs_21_sentyabrya'),
        deliveryInfo: AppLocalizations.current.getString('auto_dostavka_mezhgorod'),
        deliveryBadge: AppLocalizations.current.getString('auto_sb_23_sentyabrya_1200'),
      ),
      Supplier(
        id: '3',
        name: AppLocalizations.current.getString('auto_kakoyto_krutoy_postavschik'),
        rating: 4.9,
        reviewCount: 131,
        pricePerUnit: 810,
        minQuantity: 6,
        stockQuantity: 70,
        deliveryDate: AppLocalizations.current.getString('auto_sb_20_sentyabrya'),
        deliveryInfo: AppLocalizations.current.getString('auto_dostavka_mezhgorod'),
        deliveryBadge: AppLocalizations.current.getString('auto_chetverg_1700'),
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
