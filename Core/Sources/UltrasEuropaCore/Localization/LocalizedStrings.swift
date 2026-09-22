import Foundation

/// Translations for `L10nKey` across every `AppLanguage`.
///
/// Coverage is intentionally narrow: the tab bar labels plus a couple of
/// key Dashboard links, translated by hand into all 27 supported
/// languages. The rest of the app's text (match descriptions, activity
/// prompts, achievement copy, and so on — several hundred strings) stays
/// in English for now. That's an honest scope choice, not an oversight:
/// translating the full app accurately into 27 languages needs
/// native-speaker review this project doesn't have yet. The language
/// picker and `AppLanguage` list are built for the full expansion; only
/// the string table needs to grow to complete it.
public enum LocalizedStrings {
    public static func string(_ key: L10nKey, language: AppLanguage) -> String {
        table[key]?[language] ?? table[key]?[.english] ?? key.rawValue
    }

    static let table: [L10nKey: [AppLanguage: String]] = [
        .tabDashboard: [
            .english: "Dashboard", .bulgarian: "Табло", .croatian: "Nadzorna ploča",
            .czech: "Přehled", .danish: "Oversigt", .dutch: "Dashboard",
            .estonian: "Töölaud", .finnish: "Kojelauta", .french: "Tableau de bord",
            .german: "Übersicht", .greek: "Πίνακας", .hungarian: "Vezérlőpult",
            .irish: "Painéal", .italian: "Pannello", .latvian: "Panelis",
            .lithuanian: "Skydelis", .maltese: "Pannell", .norwegian: "Oversikt",
            .polish: "Panel", .portuguese: "Painel", .romanian: "Panou",
            .serbian: "Табла", .slovak: "Prehľad", .slovenian: "Nadzorna plošča",
            .spanish: "Panel", .swedish: "Översikt", .turkish: "Panel",
        ],
        .tabClubs: [
            .english: "Clubs", .bulgarian: "Клубове", .croatian: "Klubovi",
            .czech: "Kluby", .danish: "Klubber", .dutch: "Clubs",
            .estonian: "Klubid", .finnish: "Seurat", .french: "Clubs",
            .german: "Vereine", .greek: "Σύλλογοι", .hungarian: "Klubok",
            .irish: "Clubanna", .italian: "Club", .latvian: "Klubi",
            .lithuanian: "Klubai", .maltese: "Klabbs", .norwegian: "Klubber",
            .polish: "Kluby", .portuguese: "Clubes", .romanian: "Cluburi",
            .serbian: "Клубови", .slovak: "Kluby", .slovenian: "Klubi",
            .spanish: "Clubes", .swedish: "Klubbar", .turkish: "Kulüpler",
        ],
        .tabMatches: [
            .english: "Matches", .bulgarian: "Мачове", .croatian: "Utakmice",
            .czech: "Zápasy", .danish: "Kampe", .dutch: "Wedstrijden",
            .estonian: "Mängud", .finnish: "Ottelut", .french: "Matchs",
            .german: "Spiele", .greek: "Αγώνες", .hungarian: "Mérkőzések",
            .irish: "Cluichí", .italian: "Partite", .latvian: "Spēles",
            .lithuanian: "Rungtynės", .maltese: "Logħob", .norwegian: "Kamper",
            .polish: "Mecze", .portuguese: "Jogos", .romanian: "Meciuri",
            .serbian: "Утакмице", .slovak: "Zápasy", .slovenian: "Tekme",
            .spanish: "Partidos", .swedish: "Matcher", .turkish: "Maçlar",
        ],
        .tabChants: [
            .english: "Chants", .bulgarian: "Скандирания", .croatian: "Pjevanke",
            .czech: "Pokřiky", .danish: "Sange", .dutch: "Liederen",
            .estonian: "Laulud", .finnish: "Laulut", .french: "Chants",
            .german: "Gesänge", .greek: "Συνθήματα", .hungarian: "Rigmusok",
            .irish: "Cantaireacht", .italian: "Cori", .latvian: "Dziesmas",
            .lithuanian: "Dainos", .maltese: "Għana", .norwegian: "Sanger",
            .polish: "Śpiewy", .portuguese: "Cânticos", .romanian: "Scandări",
            .serbian: "Навијачке песме", .slovak: "Pokriky", .slovenian: "Petje",
            .spanish: "Cánticos", .swedish: "Sånger", .turkish: "Tezahürat",
        ],
        .tabGallery: [
            .english: "Gallery", .bulgarian: "Галерия", .croatian: "Galerija",
            .czech: "Galerie", .danish: "Galleri", .dutch: "Galerij",
            .estonian: "Galerii", .finnish: "Galleria", .french: "Galerie",
            .german: "Galerie", .greek: "Συλλογή", .hungarian: "Galéria",
            .irish: "Gailearaí", .italian: "Galleria", .latvian: "Galerija",
            .lithuanian: "Galerija", .maltese: "Galleria", .norwegian: "Galleri",
            .polish: "Galeria", .portuguese: "Galeria", .romanian: "Galerie",
            .serbian: "Галерија", .slovak: "Galéria", .slovenian: "Galerija",
            .spanish: "Galería", .swedish: "Galleri", .turkish: "Galeri",
        ],
        .seasonCalendar: [
            .english: "Season Calendar", .bulgarian: "Сезонен календар",
            .croatian: "Sezonski kalendar", .czech: "Sezónní kalendář",
            .danish: "Sæsonkalender", .dutch: "Seizoenskalender",
            .estonian: "Hooaja kalender", .finnish: "Kausikalenteri",
            .french: "Calendrier de saison", .german: "Saisonkalender",
            .greek: "Ημερολόγιο σεζόν", .hungarian: "Szezonnaptár",
            .irish: "Féilire Séasúir", .italian: "Calendario stagionale",
            .latvian: "Sezonas kalendārs", .lithuanian: "Sezono kalendorius",
            .maltese: "Kalendarju tal-Istaġun", .norwegian: "Sesongkalender",
            .polish: "Kalendarz sezonu", .portuguese: "Calendário da época",
            .romanian: "Calendarul sezonului", .serbian: "Сезонски календар",
            .slovak: "Sezónny kalendár", .slovenian: "Sezonski koledar",
            .spanish: "Calendario de temporada", .swedish: "Säsongskalender",
            .turkish: "Sezon Takvimi",
        ],
        .store: [
            .english: "Store", .bulgarian: "Магазин", .croatian: "Trgovina",
            .czech: "Obchod", .danish: "Butik", .dutch: "Winkel",
            .estonian: "Pood", .finnish: "Kauppa", .french: "Boutique",
            .german: "Shop", .greek: "Κατάστημα", .hungarian: "Bolt",
            .irish: "Siopa", .italian: "Negozio", .latvian: "Veikals",
            .lithuanian: "Parduotuvė", .maltese: "Ħanut", .norwegian: "Butikk",
            .polish: "Sklep", .portuguese: "Loja", .romanian: "Magazin",
            .serbian: "Продавница", .slovak: "Obchod", .slovenian: "Trgovina",
            .spanish: "Tienda", .swedish: "Butik", .turkish: "Mağaza",
        ],
        .language: [
            .english: "Language", .bulgarian: "Език", .croatian: "Jezik",
            .czech: "Jazyk", .danish: "Sprog", .dutch: "Taal",
            .estonian: "Keel", .finnish: "Kieli", .french: "Langue",
            .german: "Sprache", .greek: "Γλώσσα", .hungarian: "Nyelv",
            .irish: "Teanga", .italian: "Lingua", .latvian: "Valoda",
            .lithuanian: "Kalba", .maltese: "Lingwa", .norwegian: "Språk",
            .polish: "Język", .portuguese: "Idioma", .romanian: "Limbă",
            .serbian: "Језик", .slovak: "Jazyk", .slovenian: "Jezik",
            .spanish: "Idioma", .swedish: "Språk", .turkish: "Dil",
        ],
    ]
}
