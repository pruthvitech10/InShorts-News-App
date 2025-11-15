//
//  LocalizationManager.swift
//  Newssss
//
//  Handles app-wide localization and language switching
//  Created on 6 November 2025.
//

import Foundation
import SwiftUI
import Combine


// MARK: - LocalizationManager

@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            saveLanguage()
        }
    }
    
    private let defaults = UserDefaults.standard
    
    private init() {
        // Load saved language or use system default
        if let savedLang = defaults.string(forKey: "AppLanguage"),
           let language = AppLanguage(rawValue: savedLang) {
            currentLanguage = language
        } else {
            // Detect from system
            let systemLang = Locale.current.language.languageCode?.identifier ?? "en"
            currentLanguage = AppLanguage(rawValue: systemLang) ?? .english
        }
    }
    
    func changeLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
    
    private func saveLanguage() {
        defaults.set(currentLanguage.rawValue, forKey: "AppLanguage")
        defaults.set(currentLanguage.rawValue, forKey: "SelectedLanguage")
        defaults.synchronize()
    }
    
    func localized(_ key: String) -> String {
        return LocalizedStrings.get(key, language: currentLanguage)
    }
}

// MARK: - LocalizedStrings

// : - Localized Strings Dictionary

struct LocalizedStrings {
    static func get(_ key: String, language: AppLanguage) -> String {
        let strings = allStrings[language] ?? allStrings[.english]!
        return strings[key] ?? key
    }
    
    private static let allStrings: [AppLanguage: [String: String]] = [
        .english: [
            // Tab Bar
            "tab.home": "Home",
            "tab.search": "Search",
            "tab.bookmarks": "Bookmarks",
            "tab.profile": "Profile",
            
            // Profile
            "profile.title": "Profile",
            "profile.bookmarks": "Bookmarks",
            "profile.readToday": "Read Today",
            "profile.settings": "SETTINGS",
            "profile.notifications": "Notifications",
            "profile.language": "Language",
            "profile.privacy": "Privacy",
            "profile.about": "About",
            "profile.signOut": "Sign Out",
            "profile.signIn": "Sign In",
            "profile.signInMessage": "Sign in to sync your bookmarks and preferences across devices",
            
            // Language Settings
            "language.title": "Language",
            "language.current": "Current Language",
            "language.available": "Available Languages",
            "language.selectPreferred": "Select your preferred language for the app",
            "language.regional": "Regional Settings",
            "language.region": "Region",
            "language.currency": "Currency",
            "language.measurement": "Measurement",
            "language.dateTime": "Date & Time Preferences",
            "language.24hour": "24-Hour Time",
            "language.dateFormat": "Date Format",
            "language.interfaceDescription": "The language used throughout the app interface",
            
            // Common
            "common.cancel": "Cancel",
            "common.done": "Done",
            "common.save": "Save",
            "common.delete": "Delete",
            "common.edit": "Edit",
            "common.search": "Search",
            "common.filter": "Filter",
            "common.sort": "Sort",
            
            // Articles
            "article.translate": "Translate",
            "article.original": "Original",
            "article.read": "Read",
            "article.share": "Share",
            "article.bookmark": "Bookmark",
            
            // Categories
            "category.technology": "Technology",
            "category.business": "Business",
            "category.sports": "Sports",
            "category.entertainment": "Entertainment",
            "category.politics": "Politics",
            "category.science": "Science",
            "category.health": "Health",
            "category.general": "General",
        ],
        
        .italian: [
            // Tab Bar
            "tab.home": "Casa",
            "tab.search": "Ricerca",
            "tab.bookmarks": "Segnalibri",
            "tab.profile": "Profilo",
            
            // Profile
            "profile.title": "Profilo",
            "profile.bookmarks": "Segnalibri",
            "profile.readToday": "Letto oggi",
            "profile.settings": "IMPOSTAZIONI",
            "profile.notifications": "Notifiche",
            "profile.language": "Lingua",
            "profile.privacy": "Privacy",
            "profile.about": "Informazioni",
            "profile.signOut": "Esci",
            "profile.signIn": "Accedi",
            "profile.signInMessage": "Accedi per sincronizzare i tuoi segnalibri e le preferenze su tutti i dispositivi",
            
            // Language Settings
            "language.title": "Lingua",
            "language.current": "Lingua attuale",
            "language.available": "Lingue disponibili",
            "language.selectPreferred": "Seleziona la tua lingua preferita per l'app",
            "language.regional": "Impostazioni regionali",
            "language.region": "Regione",
            "language.currency": "Valuta",
            "language.measurement": "Misurazione",
            "language.dateTime": "Preferenze data e ora",
            "language.24hour": "Formato 24 ore",
            "language.dateFormat": "Formato data",
            "language.interfaceDescription": "La lingua utilizzata nell'interfaccia dell'app",
            
            // Common
            "common.cancel": "Annulla",
            "common.done": "Fatto",
            "common.save": "Salva",
            "common.delete": "Elimina",
            "common.edit": "Modifica",
            "common.search": "Cerca",
            "common.filter": "Filtra",
            "common.sort": "Ordina",
            
            // Articles
            "article.translate": "Traduci",
            "article.original": "Originale",
            "article.read": "Leggi",
            "article.share": "Condividi",
            "article.bookmark": "Segna",
            
            // Categories
            "category.technology": "Tecnologia",
            "category.business": "Affari",
            "category.sports": "Sport",
            "category.entertainment": "Intrattenimento",
            "category.politics": "Politica",
            "category.science": "Scienza",
            "category.health": "Salute",
            "category.general": "Generale",
        ],
        
        .spanish: [
            // Tab Bar
            "tab.home": "Inicio",
            "tab.search": "Buscar",
            "tab.bookmarks": "Marcadores",
            "tab.profile": "Perfil",
            
            // Profile
            "profile.title": "Perfil",
            "profile.bookmarks": "Marcadores",
            "profile.readToday": "Leído hoy",
            "profile.settings": "AJUSTES",
            "profile.notifications": "Notificaciones",
            "profile.language": "Idioma",
            "profile.privacy": "Privacidad",
            "profile.about": "Acerca de",
            "profile.signOut": "Cerrar sesión",
            "profile.signIn": "Iniciar sesión",
            "profile.signInMessage": "Inicia sesión para sincronizar tus marcadores y preferencias en todos los dispositivos",
            
            // Language Settings
            "language.title": "Idioma",
            "language.current": "Idioma actual",
            "language.available": "Idiomas disponibles",
            "language.selectPreferred": "Selecciona tu idioma preferido para la aplicación",
            "language.regional": "Configuración regional",
            "language.region": "Región",
            "language.currency": "Moneda",
            "language.measurement": "Medición",
            "language.dateTime": "Preferencias de fecha y hora",
            "language.24hour": "Formato de 24 horas",
            "language.dateFormat": "Formato de fecha",
            "language.interfaceDescription": "El idioma utilizado en toda la interfaz de la aplicación",
            
            // Common
            "common.cancel": "Cancelar",
            "common.done": "Hecho",
            "common.save": "Guardar",
            "common.delete": "Eliminar",
            "common.edit": "Editar",
            "common.search": "Buscar",
            "common.filter": "Filtrar",
            "common.sort": "Ordenar",
            
            // Articles
            "article.translate": "Traducir",
            "article.original": "Original",
            "article.read": "Leer",
            "article.share": "Compartir",
            "article.bookmark": "Marcar",
            
            // Categories
            "category.technology": "Tecnología",
            "category.business": "Negocios",
            "category.sports": "Deportes",
            "category.entertainment": "Entretenimiento",
            "category.politics": "Política",
            "category.science": "Ciencia",
            "category.health": "Salud",
            "category.general": "General",
        ],
        
        .french: [
            // Tab Bar
            "tab.home": "Accueil",
            "tab.search": "Rechercher",
            "tab.bookmarks": "Favoris",
            "tab.profile": "Profil",
            
            // Profile
            "profile.title": "Profil",
            "profile.bookmarks": "Favoris",
            "profile.readToday": "Lu aujourd'hui",
            "profile.settings": "PARAMÈTRES",
            "profile.notifications": "Notifications",
            "profile.language": "Langue",
            "profile.privacy": "Confidentialité",
            "profile.about": "À propos",
            "profile.signOut": "Se déconnecter",
            "profile.signIn": "Se connecter",
            "profile.signInMessage": "Connectez-vous pour synchroniser vos favoris et préférences sur tous les appareils",
            
            // Language Settings
            "language.title": "Langue",
            "language.current": "Langue actuelle",
            "language.available": "Langues disponibles",
            "language.selectPreferred": "Sélectionnez votre langue préférée pour l'application",
            "language.regional": "Paramètres régionaux",
            "language.region": "Région",
            "language.currency": "Devise",
            "language.measurement": "Mesure",
            "language.dateTime": "Préférences de date et heure",
            "language.24hour": "Format 24 heures",
            "language.dateFormat": "Format de date",
            "language.interfaceDescription": "La langue utilisée dans toute l'interface de l'application",
            
            // Common
            "common.cancel": "Annuler",
            "common.done": "Terminé",
            "common.save": "Enregistrer",
            "common.delete": "Supprimer",
            "common.edit": "Modifier",
            "common.search": "Rechercher",
            "common.filter": "Filtrer",
            "common.sort": "Trier",
            
            // Articles
            "article.translate": "Traduire",
            "article.original": "Original",
            "article.read": "Lire",
            "article.share": "Partager",
            "article.bookmark": "Marquer",
            
            // Categories
            "category.technology": "Technologie",
            "category.business": "Affaires",
            "category.sports": "Sports",
            "category.entertainment": "Divertissement",
            "category.politics": "Politique",
            "category.science": "Science",
            "category.health": "Santé",
            "category.general": "Général",
        ],
    ]
}
