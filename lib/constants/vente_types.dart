enum VenteType {
  magasin('MAG', 'Magasin'),
  tousDepots('DEP', 'Tous Dépôts');

  const VenteType(this.prefix, this.label);
  
  final String prefix;
  final String label;
}

enum StatutVente {
  brouillard('BROUILLARD'),
  journal('JOURNAL');

  const StatutVente(this.value);
  
  final String value;
}