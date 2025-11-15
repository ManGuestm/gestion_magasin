import 'package:flutter/material.dart';

// Imports statiques pour tous les modals
import '../widgets/modals/company_info_modal.dart';
import '../widgets/modals/depots_modal.dart';
import '../widgets/modals/articles_modal.dart';
import '../widgets/modals/clients_modal.dart';
import '../widgets/modals/fournisseurs_modal.dart';
import '../widgets/modals/banques_modal.dart';
import '../widgets/modals/plan_comptes_modal.dart';
import '../widgets/modals/achats_modal.dart';
import '../widgets/modals/sur_ventes_modal.dart';
import '../widgets/modals/retours_achats_modal.dart';
import '../widgets/modals/comptes_fournisseurs_modal.dart';
import '../widgets/modals/liste_achats_modal.dart';
import '../widgets/modals/liste_ventes_modal.dart';
import '../widgets/modals/mouvements_clients_modal.dart';
import '../widgets/modals/approximation_stocks_modal.dart';
import '../widgets/modals/moyen_paiement_modal.dart';
import '../widgets/modals/transferts_modal.dart';
import '../widgets/modals/gestion_emballages_modal.dart';
import '../widgets/modals/productions_modal.dart';
import '../widgets/modals/regularisation_modal.dart';
import '../widgets/modals/encaissements_modal.dart';
import '../widgets/modals/decaissements_modal.dart';
import '../widgets/modals/journal_caisse_modal.dart';
import '../widgets/modals/cheques_modal.dart';
import '../widgets/modals/journal_banques_modal.dart';
import '../widgets/modals/etats_fournisseurs_modal.dart';
import '../widgets/modals/etats_clients_modal.dart';
import '../widgets/modals/etats_articles_modal.dart';
import '../widgets/modals/etiquettes_prix_modal.dart';
import '../widgets/modals/etat_tarifaire_modal.dart';
import '../widgets/modals/etat_stocks_modal.dart';
import '../widgets/modals/mouvement_stocks_journalieres_modal.dart';
import '../widgets/modals/fiche_stocks_modal.dart';
import '../widgets/modals/estimation_valeur_articles_modal.dart';
import '../widgets/modals/regularisation_compte_commerciaux_modal.dart';
import '../widgets/modals/relance_clients_modal.dart';
import '../widgets/modals/echeance_fournisseurs_modal.dart';
import '../widgets/modals/variation_stocks_modal.dart';
import '../widgets/modals/mise_a_jour_valeurs_stocks_modal.dart';
import '../widgets/modals/niveau_stocks_modal.dart';
import '../widgets/modals/amortissement_immobilisations_modal.dart';
import '../widgets/modals/reactualisation_base_donnees_modal.dart';
import '../widgets/modals/effet_a_recevoir_modal.dart';
import '../widgets/modals/virements_internes_modal.dart';
import '../widgets/modals/operations_caisses_modal.dart';
import '../widgets/modals/operations_banques_modal.dart';
import '../widgets/modals/etats_commerciaux_modal.dart';
import '../widgets/modals/etats_immobilisations_modal.dart';
import '../widgets/modals/etats_autres_comptes_modal.dart';
import '../widgets/modals/statistiques_ventes_modal.dart';
import '../widgets/modals/statistiques_achats_modal.dart';
import '../widgets/modals/marges_modal.dart';
import '../widgets/modals/tableau_bord_modal.dart';
import '../widgets/modals/bilan_compte_resultat_modal.dart';
import '../widgets/modals/statistiques_fournisseurs_modal.dart';
import '../widgets/modals/reinitialiser_donnees_modal.dart';
import '../widgets/modals/users_management_modal.dart';
import '../widgets/modals/profil_modal.dart';

class ModalLoader {
  static final Map<String, Widget Function()> _factories = {};
  static final Map<String, Widget> _cache = {};
  static bool _initialized = false;

  static void _initializeFactories() {
    if (_initialized) return;
    
    _factories.addAll({
      'Informations sur la société': () => const CompanyInfoModal(),
      'Dépôts': () => const DepotsModal(),
      'Articles': () => const ArticlesModal(),
      'Clients': () => const ClientsModal(),
      'Fournisseurs': () => const FournisseursModal(),
      'Gestion fournisseurs': () => const FournisseursModal(),
      'Banques': () => const BanquesModal(),
      'Plan de comptes': () => const PlanComptesModal(),
      'Achats': () => const AchatsModal(),
      'Sur Ventes': () => const SurVentesModal(),
      'Retours achats': () => const RetoursAchatsModal(),
      'Comptes fournisseurs': () => const ComptesFournisseursModal(),
      'Liste des achats': () => const ListeAchatsModal(),
      'Liste des ventes': () => const ListeVentesModal(),
      'Mouvements Clients': () => const MouvementsClientsModal(),
      'Approximation Stocks ...': () => const ApproximationStocksModal(),
      'Moyen de paiement': () => const MoyenPaiementModal(),
      'Transferts': () => const TransfertsModal(),
      'Transfert de Marchandises': () => const TransfertsModal(),
      'Gestion Emballages': () => const GestionEmballagesModal(),
      'Productions': () => const ProductionsModal(),
      'Régularisation compte tiers': () => const RegularisationModal(),
      'Encaissements': () => const EncaissementsModal(),
      'Décaissements': () => const DecaissementsModal(),
      'Journal de caisse': () => const JournalCaisseModal(),
      'Chèques': () => const ChequesModal(),
      'Journal des banques': () => const JournalBanquesModal(),
      'Etats Fournisseurs': () => const EtatsFournisseursModal(),
      'Etats Clients': () => const EtatsClientsModal(),
      'Etats Articles': () => const EtatsArticlesModal(),
      'Etiquettes de prix': () => const EtiquettesPrixModal(),
      'Etat tarifaire': () => const EtatTarifaireModal(),
      'Etat de stocks': () => const EtatStocksModal(),
      'Mouvement de stocks journalières': () => const MouvementStocksJournalieresModal(),
      'Fiche de stocks': () => const FicheStocksModal(),
      'Estimation en valeur des articles (CMUP)': () => const EstimationValeurArticlesModal(),
      'Régularisation compte Commerciaux': () => const RegularisationCompteCommerciauxModal(),
      'Relance Clients': () => const RelanceClientsModal(),
      'Echéance Fournisseurs': () => const EchanceFournisseursModal(),
      'Variation des stocks': () => const VariationStocksModal(),
      'Mise à jour des valeurs de stocks': () => const MiseAJourValeursStocksModal(),
      'Niveau des stocks (Articles à commandées)': () => const NiveauStocksModal(),
      'Amortissement des immobilisations': () => const AmortissementImmobilisationsModal(),
      'Réactualisation de la base de données': () => const ReactualisationBaseDonneesModal(),
      'Effet à recevoir': () => const EffetARecevoirModal(),
      'Virements Internes': () => const VirementsInternesModal(),
      'Opérations Caisses': () => const OperationsCaissesModal(),
      'Opérations Banques': () => const OperationsBanquesModal(),
      'Etats Commerciaux': () => const EtatsCommerciauxModal(),
      'Etats Immobilisations': () => const EtatsImmobilisationsModal(),
      'Etats Autres Comptes': () => const EtatsAutresComptesModal(),
      'Statistiques de ventes': () => const StatistiquesVentesModal(),
      'Statistiques d\'achats': () => const StatistiquesAchatsModal(),
      'Marges': () => const MargesModal(),
      'tableau de bord': () => const TableauBordModal(),
      'Bilan / Compte de Résultat': () => const BilanCompteResultatModal(),
      'Statistiques fournisseurs': () => const StatistiquesFournisseursModal(),
      'Réinitialiser les données': () => const ReinitialiserDonneesModal(),
      'Gestion des utilisateurs': () => const UsersManagementModal(),
      'Profil': () => const ProfilModal(),
    });
    
    _initialized = true;
  }

  static Future<Widget?> loadModal(String item) async {
    _initializeFactories();
    
    // Vérifier le cache d'abord
    if (_cache.containsKey(item)) {
      return _cache[item];
    }

    final factory = _factories[item];
    if (factory == null) return null;
    
    // Créer le widget de manière asynchrone pour ne pas bloquer l'UI
    await Future.delayed(Duration.zero);
    
    final modal = factory();
    
    // Mettre en cache seulement les modals fréquemment utilisés
    if (_isFrequentModal(item)) {
      _cache[item] = modal;
    }
    
    return modal;
  }
  
  static bool _isFrequentModal(String item) {
    const frequentModals = {
      'Articles',
      'Clients', 
      'Fournisseurs',
      'Achats',
      'Ventes',
      'Etats Articles',
      'Etats Clients'
    };
    return frequentModals.contains(item);
  }


  static void clearCache() {
    _cache.clear();
  }

  static void preloadFrequentModals() {
    // Pré-charger les modals les plus utilisés en arrière-plan
    Future.microtask(() async {
      final frequentModals = [
        'Articles',
        'Clients', 
        'Fournisseurs',
        'Achats'
      ];
      
      for (final modal in frequentModals) {
        try {
          await loadModal(modal);
        } catch (e) {
          // Ignorer les erreurs de pré-chargement
        }
      }
    });
  }
  
  static int getCacheSize() => _cache.length;
  
  static List<String> getCachedModals() => _cache.keys.toList();
}