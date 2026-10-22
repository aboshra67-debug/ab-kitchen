import 'package:flutter/material.dart';
import '../branding/brand_widgets.dart';
import '../core/models.dart';

/// Photorealistic original food illustration assets shipped with the app.
/// Bundled assets need no network connection and cannot trigger extra downloads.
/// Do not show another recipe's photo as a fallback for an unmatched recipe.
class RecipePhoto extends StatelessWidget {
  const RecipePhoto({super.key, required this.recipe, this.height = 184, this.hero = false,
    this.borderRadius = 18});
  final Recipe recipe;
  final double height;
  final bool hero;
  final double borderRadius;

  static const picturedRecipes = <String>{
    'eg_eggplant_pickled', // V0.7.4 individually matched illustration
    'eg_yogurt_cucumber', // V0.7.4 individually matched illustration
    'eg_pickled_turnip', // V0.7.4 individually matched illustration
    'eg_tomato_daqa', // V0.7.4 individually matched illustration
    'eg_meshabbak_domyat', // V0.7.4 individually matched illustration
    'eg_sawabe_zainab', // V0.7.4 individually matched illustration
    'eg_shakalama', // V0.7.4 individually matched illustration
    'eg_semsemiya', // V0.7.4 individually matched illustration
    'eg_ghorayeba', // V0.7.4 individually matched illustration
    'eg_petit_four', // V0.7.4 individually matched illustration
    'eg_mahalabiya', // V0.7.4 individually matched illustration
    'eg_asoura', // V0.7.4 individually matched illustration
    'eg_atayef_nuts', // V0.7.4 individually matched illustration
    'eg_balh_sham', // V0.7.4 individually matched illustration
    'eg_zalabia', // V0.7.4 individually matched illustration
    'eg_kahk_eid', // V0.7.4 individually matched illustration
    'eg_koshari','eg_molokhia','eg_mahshi','eg_ful','eg_besbousa',
    'eg_macaroni_beshamel','eg_hawawshi','eg_mombar','eg_kofta_rice',
    'eg_tahini_salad','eg_salata_baladi','eg_cabbage_mahshi',
    'eg_kishk_egyptian','eg_baladi_bread','eg_lentil_soup',
    'sa_kabsa','sa_jareesh','sa_saleeg','sa_mutabbaq','sa_luqaimat',
    // Saudi phase 1 — 20 independently authored, offline WebP photographs.
    // Saudi phase 2: 20 standalone offline JPEG illustrations.
    'sa_daghabees','sa_mersa','sa_mufallaq_shrimp','sa_asidah','sa_millet_soup','sa_habb_soup','sa_arboud_bread','sa_qishd','sa_masabeeb','sa_mashghoutha','sa_mathloutha','sa_shaatha','sa_mahshoush','sa_maifa_bread','sa_tasabee','sa_mafalit','sa_mardhoufa','sa_fahsa','sa_moqalqal','sa_khameer_red',
    'sa_marqooq','sa_qursan','sa_matazeez','sa_haneeth','sa_madini_rice','sa_hasawi_rice','sa_sayadiyah_tabuk','sa_maghsh_jazan','sa_ruqsh_najran','sa_mlaihiyya','sa_bakeelah_jawf','sa_muqanah_bahah','sa_kubaibat_hail','sa_kleija_qassim','sa_maqshush','sa_areeka','sa_haneeni','sa_balila_hijazi','sa_masoob','sa_tamees',
    'sy_fatteh','sy_kibbeh','sy_muhammara','sy_shishbarak',
    'sy_hariseh','tr_menemen',
    'eg_dessert_rice_pudding','eg_dessert_qashtuta','eg_dessert_sweet_koshari',
    'eg_dessert_om_ali','eg_dessert_belila','eg_dessert_cassata',
    'eg_dessert_salankateeh','eg_dessert_loaa','eg_dessert_bamboza',
    'eg_dessert_cake','eg_dessert_crepe','eg_dessert_creme_brulee',
    'eg_dessert_sah_adah_ambo','eg_dessert_motakandera',
    // V0.7.1: per-recipe images staged and validated by the offline bundling pipeline.
    'eg_baba_ghanoush',    'eg_boiled_fava_green',    'eg_bouri_oven',
    'eg_calamari_fried',    'eg_calamari_tagine',    'eg_cheese_tomato',
    'eg_chicken_cream_mushroom',    'eg_chicken_cream_soup',    'eg_chicken_roasted_onion',
    'eg_dawood_basha',    'eg_duqqa_alex',    'eg_egg_omelet_veg',
    'eg_egg_pastrami',    'eg_eggplant_minced',    'eg_eggs_potatoes',
    'eg_fasolia_green',    'eg_fatta_chicken',    'eg_fatta_meat',
    'eg_fesikh_salad',    'eg_feteer_cream',    'eg_feteer_meshaltet',
    'eg_feteer_sugar',    'eg_fish_singari',    'eg_fish_tahini',
    'eg_flahy_qors',    'eg_fried_eggplant_breakfast',    'eg_glash_meat_tray',
    'eg_kaware3',    'eg_kebab_halla',    'eg_kofta_oven',
    'eg_kunafa_cream',    'eg_lentil_rice',    'eg_liver_alexandria',
    'eg_loubia_white',    'eg_macaroni_oven_meat',    'eg_meat_broth',
    'eg_molokhia_plain',    'eg_molokhia_rabbit',    'eg_moussaka',
    'eg_moza_veg',    'eg_okka_tagine',    'eg_okra_meat',
    'eg_okra_shrimp_tagine',    'eg_old_cheese_salad',    'eg_onion_mahshi',
    'eg_orzo_soup',    'eg_orzo_tagine',    'eg_oxtail_tagine',
    'eg_peas_carrots',    'eg_pigeon_freekeh',    'eg_pigeon_rice',
    'eg_potato_chicken_tray',    'eg_potato_mahshi_meat',    'eg_potato_meat_tray',
    'eg_qurasa_milk',    'eg_rice_moammar',    'eg_ro2a2_meat',
    'eg_roasted_duck',    'eg_sardines_fried',    'eg_sayadeya_rice',
    'eg_seafood_soup_eg',    'eg_shakshuka_egypt',    'eg_shrimp_alex',
    'eg_shrimp_red_sauce',    'eg_sogo2_alexandria',    'eg_spinach_chickpeas',
    'eg_stuffed_tomatoes',    'eg_taameya',    'eg_tarro_chard',
    'eg_tilapia_fried',    'eg_tilapia_grilled',    'eg_tomato_soup',
    'eg_torb',    'eg_torly_oven',    'eg_vegetable_soup',
    'eg_vine_leaves_meat',    'eg_wara2_3enab',    'in_biryani',
    'in_chana',    'in_dal',    'it_pasta',
    'it_pizza',    'it_risotto',    'lb_fattoush',
    'lb_hummus',    'lb_tabbouleh',    'ma_couscous',
    'ma_harira',    'ma_tajine',    'tr_kofte',
    'tr_lentil',

  };

  static const saudiPhase2Jpg = <String>{
    'sa_daghabees','sa_mersa','sa_mufallaq_shrimp','sa_asidah','sa_millet_soup','sa_habb_soup','sa_arboud_bread','sa_qishd','sa_masabeeb','sa_mashghoutha','sa_mathloutha','sa_shaatha','sa_mahshoush','sa_maifa_bread','sa_tasabee','sa_mafalit','sa_mardhoufa','sa_fahsa','sa_moqalqal','sa_khameer_red'
  };

  // Backward-compatible alias used by existing V0.7.1 photo coverage tests.
  static const saudiPhase2JpegIds = saudiPhase2Jpg;

  static String? assetFor(String id, {bool hero = false}) {
    if (!picturedRecipes.contains(id)) return null;
    if (id == 'eg_koshari' && hero) return 'assets/photos/eg_koshari_hero.webp';
    if (saudiPhase2Jpg.contains(id)) return 'assets/photos/$id.jpg';
    return 'assets/photos/$id.webp';
  }

  @override
  Widget build(BuildContext context) {
    final path = assetFor(recipe.id, hero: hero);
    final palette = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: path == null
          ? ColoredBox(color: palette.primaryContainer.withValues(alpha: .45),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(recipe.emoji, style: TextStyle(fontSize: height < 135 ? 32 : 48)),
                if (height >= 135) ...[
                  const SizedBox(height: 2),
                  Text('صورة الوصفة قريبًا', style: TextStyle(fontSize: 11,
                    color: palette.onSurfaceVariant)),
                ],
              ]))
          : Image.asset(path, fit: BoxFit.cover, filterQuality: FilterQuality.medium,
              semanticLabel: 'صورة توضيحية واقعية المظهر لطبق ${recipe.name}',
              errorBuilder: (_, __, ___) => ColoredBox(
                color: KitchenBrand.roseCream,
                child: Center(child: Text(recipe.emoji,
                  style: const TextStyle(fontSize: 55))))),
      ),
    );
  }
}