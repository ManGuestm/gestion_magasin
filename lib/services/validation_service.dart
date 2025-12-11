class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult.valid() : isValid = true, errorMessage = null;
  ValidationResult.invalid(this.errorMessage) : isValid = false;
}

class ValidationService {
  /// Valide un email
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult.invalid('L\'email est requis');
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return ValidationResult.invalid('Format d\'email invalide');
    }
    
    return ValidationResult.valid();
  }

  /// Valide un numéro de téléphone
  static ValidationResult validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return ValidationResult.valid(); // Optionnel
    }
    
    final phoneRegex = RegExp(r'^[+]?[0-9\s\-\(\)]{8,15}$');
    if (!phoneRegex.hasMatch(phone.trim())) {
      return ValidationResult.invalid('Format de téléphone invalide');
    }
    
    return ValidationResult.valid();
  }

  /// Valide un montant
  static ValidationResult validateAmount(String? amount, {bool required = true}) {
    if (amount == null || amount.trim().isEmpty) {
      return required 
        ? ValidationResult.invalid('Le montant est requis')
        : ValidationResult.valid();
    }
    
    final double? value = double.tryParse(amount.trim());
    if (value == null) {
      return ValidationResult.invalid('Montant invalide');
    }
    
    if (value < 0) {
      return ValidationResult.invalid('Le montant ne peut pas être négatif');
    }
    
    return ValidationResult.valid();
  }

  /// Valide une quantité
  static ValidationResult validateQuantity(String? quantity, {bool required = true}) {
    if (quantity == null || quantity.trim().isEmpty) {
      return required 
        ? ValidationResult.invalid('La quantité est requise')
        : ValidationResult.valid();
    }
    
    final double? value = double.tryParse(quantity.trim());
    if (value == null) {
      return ValidationResult.invalid('Quantité invalide');
    }
    
    if (value <= 0) {
      return ValidationResult.invalid('La quantité doit être positive');
    }
    
    return ValidationResult.valid();
  }

  /// Valide un nom/désignation
  static ValidationResult validateName(String? name, {String fieldName = 'Nom'}) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult.invalid('$fieldName est requis');
    }
    
    if (name.trim().length < 2) {
      return ValidationResult.invalid('$fieldName doit contenir au moins 2 caractères');
    }
    
    if (name.trim().length > 100) {
      return ValidationResult.invalid('$fieldName ne peut pas dépasser 100 caractères');
    }
    
    return ValidationResult.valid();
  }

  /// Valide un NIF (Numéro d'Identification Fiscale)
  static ValidationResult validateNIF(String? nif) {
    if (nif == null || nif.trim().isEmpty) {
      return ValidationResult.valid(); // Optionnel
    }
    
    // Format NIF Madagascar: 9 chiffres
    final nifRegex = RegExp(r'^\d{9}$');
    if (!nifRegex.hasMatch(nif.trim())) {
      return ValidationResult.invalid('NIF doit contenir 9 chiffres');
    }
    
    return ValidationResult.valid();
  }

  /// Valide un STAT
  static ValidationResult validateSTAT(String? stat) {
    if (stat == null || stat.trim().isEmpty) {
      return ValidationResult.valid(); // Optionnel
    }
    
    // Format STAT Madagascar: 5 chiffres + 3 chiffres + 3 chiffres + 6 chiffres
    final statRegex = RegExp(r'^\d{5}\s?\d{3}\s?\d{3}\s?\d{6}$');
    if (!statRegex.hasMatch(stat.trim())) {
      return ValidationResult.invalid('Format STAT invalide');
    }
    
    return ValidationResult.valid();
  }

  /// Valide une date
  static ValidationResult validateDate(DateTime? date, {bool required = true}) {
    if (date == null) {
      return required 
        ? ValidationResult.invalid('La date est requise')
        : ValidationResult.valid();
    }
    
    final now = DateTime.now();
    final minDate = DateTime(1900);
    final maxDate = DateTime(now.year + 10);
    
    if (date.isBefore(minDate) || date.isAfter(maxDate)) {
      return ValidationResult.invalid('Date invalide');
    }
    
    return ValidationResult.valid();
  }

  /// Valide un stock
  static ValidationResult validateStock(double? stock) {
    if (stock == null) {
      return ValidationResult.valid(); // Peut être null
    }
    
    if (stock < 0) {
      return ValidationResult.invalid('Le stock ne peut pas être négatif');
    }
    
    return ValidationResult.valid();
  }

  /// Valide un pourcentage
  static ValidationResult validatePercentage(String? percentage) {
    if (percentage == null || percentage.trim().isEmpty) {
      return ValidationResult.valid(); // Optionnel
    }
    
    final double? value = double.tryParse(percentage.trim());
    if (value == null) {
      return ValidationResult.invalid('Pourcentage invalide');
    }
    
    if (value < 0 || value > 100) {
      return ValidationResult.invalid('Le pourcentage doit être entre 0 et 100');
    }
    
    return ValidationResult.valid();
  }

  /// Valide plusieurs champs à la fois
  static List<String> validateMultiple(Map<String, ValidationResult> validations) {
    return validations.entries
        .where((entry) => !entry.value.isValid)
        .map((entry) => entry.value.errorMessage!)
        .toList();
  }
}