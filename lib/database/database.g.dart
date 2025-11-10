// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SocTable extends Soc with TableInfo<$SocTable, SocData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SocTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  @override
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
      'ref', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _rsocMeta = const VerificationMeta('rsoc');
  @override
  late final GeneratedColumn<String> rsoc = GeneratedColumn<String>(
      'rsoc', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _activitesMeta =
      const VerificationMeta('activites');
  @override
  late final GeneratedColumn<String> activites = GeneratedColumn<String>(
      'activites', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _adrMeta = const VerificationMeta('adr');
  @override
  late final GeneratedColumn<String> adr = GeneratedColumn<String>(
      'adr', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _logoMeta = const VerificationMeta('logo');
  @override
  late final GeneratedColumn<String> logo = GeneratedColumn<String>(
      'logo', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _capitalMeta =
      const VerificationMeta('capital');
  @override
  late final GeneratedColumn<double> capital = GeneratedColumn<double>(
      'capital', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _rcsMeta = const VerificationMeta('rcs');
  @override
  late final GeneratedColumn<String> rcs = GeneratedColumn<String>(
      'rcs', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _nifMeta = const VerificationMeta('nif');
  @override
  late final GeneratedColumn<String> nif = GeneratedColumn<String>(
      'nif', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _statMeta = const VerificationMeta('stat');
  @override
  late final GeneratedColumn<String> stat = GeneratedColumn<String>(
      'stat', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _telMeta = const VerificationMeta('tel');
  @override
  late final GeneratedColumn<String> tel = GeneratedColumn<String>(
      'tel', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<String> port = GeneratedColumn<String>(
      'port', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _siteMeta = const VerificationMeta('site');
  @override
  late final GeneratedColumn<String> site = GeneratedColumn<String>(
      'site', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _faxMeta = const VerificationMeta('fax');
  @override
  late final GeneratedColumn<String> fax = GeneratedColumn<String>(
      'fax', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _telexMeta = const VerificationMeta('telex');
  @override
  late final GeneratedColumn<String> telex = GeneratedColumn<String>(
      'telex', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _tvaMeta = const VerificationMeta('tva');
  @override
  late final GeneratedColumn<double> tva = GeneratedColumn<double>(
      'tva', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _tMeta = const VerificationMeta('t');
  @override
  late final GeneratedColumn<double> t = GeneratedColumn<double>(
      't', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _valMeta = const VerificationMeta('val');
  @override
  late final GeneratedColumn<String> val = GeneratedColumn<String>(
      'val', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _cifMeta = const VerificationMeta('cif');
  @override
  late final GeneratedColumn<String> cif = GeneratedColumn<String>(
      'cif', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        ref,
        rsoc,
        activites,
        adr,
        logo,
        capital,
        rcs,
        nif,
        stat,
        tel,
        port,
        email,
        site,
        fax,
        telex,
        tva,
        t,
        val,
        cif
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'soc';
  @override
  VerificationContext validateIntegrity(Insertable<SocData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ref')) {
      context.handle(
          _refMeta, ref.isAcceptableOrUnknown(data['ref']!, _refMeta));
    } else if (isInserting) {
      context.missing(_refMeta);
    }
    if (data.containsKey('rsoc')) {
      context.handle(
          _rsocMeta, rsoc.isAcceptableOrUnknown(data['rsoc']!, _rsocMeta));
    }
    if (data.containsKey('activites')) {
      context.handle(_activitesMeta,
          activites.isAcceptableOrUnknown(data['activites']!, _activitesMeta));
    }
    if (data.containsKey('adr')) {
      context.handle(
          _adrMeta, adr.isAcceptableOrUnknown(data['adr']!, _adrMeta));
    }
    if (data.containsKey('logo')) {
      context.handle(
          _logoMeta, logo.isAcceptableOrUnknown(data['logo']!, _logoMeta));
    }
    if (data.containsKey('capital')) {
      context.handle(_capitalMeta,
          capital.isAcceptableOrUnknown(data['capital']!, _capitalMeta));
    }
    if (data.containsKey('rcs')) {
      context.handle(
          _rcsMeta, rcs.isAcceptableOrUnknown(data['rcs']!, _rcsMeta));
    }
    if (data.containsKey('nif')) {
      context.handle(
          _nifMeta, nif.isAcceptableOrUnknown(data['nif']!, _nifMeta));
    }
    if (data.containsKey('stat')) {
      context.handle(
          _statMeta, stat.isAcceptableOrUnknown(data['stat']!, _statMeta));
    }
    if (data.containsKey('tel')) {
      context.handle(
          _telMeta, tel.isAcceptableOrUnknown(data['tel']!, _telMeta));
    }
    if (data.containsKey('port')) {
      context.handle(
          _portMeta, port.isAcceptableOrUnknown(data['port']!, _portMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('site')) {
      context.handle(
          _siteMeta, site.isAcceptableOrUnknown(data['site']!, _siteMeta));
    }
    if (data.containsKey('fax')) {
      context.handle(
          _faxMeta, fax.isAcceptableOrUnknown(data['fax']!, _faxMeta));
    }
    if (data.containsKey('telex')) {
      context.handle(
          _telexMeta, telex.isAcceptableOrUnknown(data['telex']!, _telexMeta));
    }
    if (data.containsKey('tva')) {
      context.handle(
          _tvaMeta, tva.isAcceptableOrUnknown(data['tva']!, _tvaMeta));
    }
    if (data.containsKey('t')) {
      context.handle(_tMeta, t.isAcceptableOrUnknown(data['t']!, _tMeta));
    }
    if (data.containsKey('val')) {
      context.handle(
          _valMeta, val.isAcceptableOrUnknown(data['val']!, _valMeta));
    }
    if (data.containsKey('cif')) {
      context.handle(
          _cifMeta, cif.isAcceptableOrUnknown(data['cif']!, _cifMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ref};
  @override
  SocData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SocData(
      ref: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref'])!,
      rsoc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rsoc']),
      activites: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activites']),
      adr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}adr']),
      logo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logo']),
      capital: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}capital']),
      rcs: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rcs']),
      nif: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nif']),
      stat: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stat']),
      tel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tel']),
      port: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}port']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      site: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}site']),
      fax: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fax']),
      telex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}telex']),
      tva: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tva']),
      t: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}t']),
      val: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}val']),
      cif: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cif']),
    );
  }

  @override
  $SocTable createAlias(String alias) {
    return $SocTable(attachedDatabase, alias);
  }
}

class SocData extends DataClass implements Insertable<SocData> {
  final String ref;
  final String? rsoc;
  final String? activites;
  final String? adr;
  final String? logo;
  final double? capital;
  final String? rcs;
  final String? nif;
  final String? stat;
  final String? tel;
  final String? port;
  final String? email;
  final String? site;
  final String? fax;
  final String? telex;
  final double? tva;
  final double? t;
  final String? val;
  final String? cif;
  const SocData(
      {required this.ref,
      this.rsoc,
      this.activites,
      this.adr,
      this.logo,
      this.capital,
      this.rcs,
      this.nif,
      this.stat,
      this.tel,
      this.port,
      this.email,
      this.site,
      this.fax,
      this.telex,
      this.tva,
      this.t,
      this.val,
      this.cif});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ref'] = Variable<String>(ref);
    if (!nullToAbsent || rsoc != null) {
      map['rsoc'] = Variable<String>(rsoc);
    }
    if (!nullToAbsent || activites != null) {
      map['activites'] = Variable<String>(activites);
    }
    if (!nullToAbsent || adr != null) {
      map['adr'] = Variable<String>(adr);
    }
    if (!nullToAbsent || logo != null) {
      map['logo'] = Variable<String>(logo);
    }
    if (!nullToAbsent || capital != null) {
      map['capital'] = Variable<double>(capital);
    }
    if (!nullToAbsent || rcs != null) {
      map['rcs'] = Variable<String>(rcs);
    }
    if (!nullToAbsent || nif != null) {
      map['nif'] = Variable<String>(nif);
    }
    if (!nullToAbsent || stat != null) {
      map['stat'] = Variable<String>(stat);
    }
    if (!nullToAbsent || tel != null) {
      map['tel'] = Variable<String>(tel);
    }
    if (!nullToAbsent || port != null) {
      map['port'] = Variable<String>(port);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || site != null) {
      map['site'] = Variable<String>(site);
    }
    if (!nullToAbsent || fax != null) {
      map['fax'] = Variable<String>(fax);
    }
    if (!nullToAbsent || telex != null) {
      map['telex'] = Variable<String>(telex);
    }
    if (!nullToAbsent || tva != null) {
      map['tva'] = Variable<double>(tva);
    }
    if (!nullToAbsent || t != null) {
      map['t'] = Variable<double>(t);
    }
    if (!nullToAbsent || val != null) {
      map['val'] = Variable<String>(val);
    }
    if (!nullToAbsent || cif != null) {
      map['cif'] = Variable<String>(cif);
    }
    return map;
  }

  SocCompanion toCompanion(bool nullToAbsent) {
    return SocCompanion(
      ref: Value(ref),
      rsoc: rsoc == null && nullToAbsent ? const Value.absent() : Value(rsoc),
      activites: activites == null && nullToAbsent
          ? const Value.absent()
          : Value(activites),
      adr: adr == null && nullToAbsent ? const Value.absent() : Value(adr),
      logo: logo == null && nullToAbsent ? const Value.absent() : Value(logo),
      capital: capital == null && nullToAbsent
          ? const Value.absent()
          : Value(capital),
      rcs: rcs == null && nullToAbsent ? const Value.absent() : Value(rcs),
      nif: nif == null && nullToAbsent ? const Value.absent() : Value(nif),
      stat: stat == null && nullToAbsent ? const Value.absent() : Value(stat),
      tel: tel == null && nullToAbsent ? const Value.absent() : Value(tel),
      port: port == null && nullToAbsent ? const Value.absent() : Value(port),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      site: site == null && nullToAbsent ? const Value.absent() : Value(site),
      fax: fax == null && nullToAbsent ? const Value.absent() : Value(fax),
      telex:
          telex == null && nullToAbsent ? const Value.absent() : Value(telex),
      tva: tva == null && nullToAbsent ? const Value.absent() : Value(tva),
      t: t == null && nullToAbsent ? const Value.absent() : Value(t),
      val: val == null && nullToAbsent ? const Value.absent() : Value(val),
      cif: cif == null && nullToAbsent ? const Value.absent() : Value(cif),
    );
  }

  factory SocData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SocData(
      ref: serializer.fromJson<String>(json['ref']),
      rsoc: serializer.fromJson<String?>(json['rsoc']),
      activites: serializer.fromJson<String?>(json['activites']),
      adr: serializer.fromJson<String?>(json['adr']),
      logo: serializer.fromJson<String?>(json['logo']),
      capital: serializer.fromJson<double?>(json['capital']),
      rcs: serializer.fromJson<String?>(json['rcs']),
      nif: serializer.fromJson<String?>(json['nif']),
      stat: serializer.fromJson<String?>(json['stat']),
      tel: serializer.fromJson<String?>(json['tel']),
      port: serializer.fromJson<String?>(json['port']),
      email: serializer.fromJson<String?>(json['email']),
      site: serializer.fromJson<String?>(json['site']),
      fax: serializer.fromJson<String?>(json['fax']),
      telex: serializer.fromJson<String?>(json['telex']),
      tva: serializer.fromJson<double?>(json['tva']),
      t: serializer.fromJson<double?>(json['t']),
      val: serializer.fromJson<String?>(json['val']),
      cif: serializer.fromJson<String?>(json['cif']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ref': serializer.toJson<String>(ref),
      'rsoc': serializer.toJson<String?>(rsoc),
      'activites': serializer.toJson<String?>(activites),
      'adr': serializer.toJson<String?>(adr),
      'logo': serializer.toJson<String?>(logo),
      'capital': serializer.toJson<double?>(capital),
      'rcs': serializer.toJson<String?>(rcs),
      'nif': serializer.toJson<String?>(nif),
      'stat': serializer.toJson<String?>(stat),
      'tel': serializer.toJson<String?>(tel),
      'port': serializer.toJson<String?>(port),
      'email': serializer.toJson<String?>(email),
      'site': serializer.toJson<String?>(site),
      'fax': serializer.toJson<String?>(fax),
      'telex': serializer.toJson<String?>(telex),
      'tva': serializer.toJson<double?>(tva),
      't': serializer.toJson<double?>(t),
      'val': serializer.toJson<String?>(val),
      'cif': serializer.toJson<String?>(cif),
    };
  }

  SocData copyWith(
          {String? ref,
          Value<String?> rsoc = const Value.absent(),
          Value<String?> activites = const Value.absent(),
          Value<String?> adr = const Value.absent(),
          Value<String?> logo = const Value.absent(),
          Value<double?> capital = const Value.absent(),
          Value<String?> rcs = const Value.absent(),
          Value<String?> nif = const Value.absent(),
          Value<String?> stat = const Value.absent(),
          Value<String?> tel = const Value.absent(),
          Value<String?> port = const Value.absent(),
          Value<String?> email = const Value.absent(),
          Value<String?> site = const Value.absent(),
          Value<String?> fax = const Value.absent(),
          Value<String?> telex = const Value.absent(),
          Value<double?> tva = const Value.absent(),
          Value<double?> t = const Value.absent(),
          Value<String?> val = const Value.absent(),
          Value<String?> cif = const Value.absent()}) =>
      SocData(
        ref: ref ?? this.ref,
        rsoc: rsoc.present ? rsoc.value : this.rsoc,
        activites: activites.present ? activites.value : this.activites,
        adr: adr.present ? adr.value : this.adr,
        logo: logo.present ? logo.value : this.logo,
        capital: capital.present ? capital.value : this.capital,
        rcs: rcs.present ? rcs.value : this.rcs,
        nif: nif.present ? nif.value : this.nif,
        stat: stat.present ? stat.value : this.stat,
        tel: tel.present ? tel.value : this.tel,
        port: port.present ? port.value : this.port,
        email: email.present ? email.value : this.email,
        site: site.present ? site.value : this.site,
        fax: fax.present ? fax.value : this.fax,
        telex: telex.present ? telex.value : this.telex,
        tva: tva.present ? tva.value : this.tva,
        t: t.present ? t.value : this.t,
        val: val.present ? val.value : this.val,
        cif: cif.present ? cif.value : this.cif,
      );
  SocData copyWithCompanion(SocCompanion data) {
    return SocData(
      ref: data.ref.present ? data.ref.value : this.ref,
      rsoc: data.rsoc.present ? data.rsoc.value : this.rsoc,
      activites: data.activites.present ? data.activites.value : this.activites,
      adr: data.adr.present ? data.adr.value : this.adr,
      logo: data.logo.present ? data.logo.value : this.logo,
      capital: data.capital.present ? data.capital.value : this.capital,
      rcs: data.rcs.present ? data.rcs.value : this.rcs,
      nif: data.nif.present ? data.nif.value : this.nif,
      stat: data.stat.present ? data.stat.value : this.stat,
      tel: data.tel.present ? data.tel.value : this.tel,
      port: data.port.present ? data.port.value : this.port,
      email: data.email.present ? data.email.value : this.email,
      site: data.site.present ? data.site.value : this.site,
      fax: data.fax.present ? data.fax.value : this.fax,
      telex: data.telex.present ? data.telex.value : this.telex,
      tva: data.tva.present ? data.tva.value : this.tva,
      t: data.t.present ? data.t.value : this.t,
      val: data.val.present ? data.val.value : this.val,
      cif: data.cif.present ? data.cif.value : this.cif,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SocData(')
          ..write('ref: $ref, ')
          ..write('rsoc: $rsoc, ')
          ..write('activites: $activites, ')
          ..write('adr: $adr, ')
          ..write('logo: $logo, ')
          ..write('capital: $capital, ')
          ..write('rcs: $rcs, ')
          ..write('nif: $nif, ')
          ..write('stat: $stat, ')
          ..write('tel: $tel, ')
          ..write('port: $port, ')
          ..write('email: $email, ')
          ..write('site: $site, ')
          ..write('fax: $fax, ')
          ..write('telex: $telex, ')
          ..write('tva: $tva, ')
          ..write('t: $t, ')
          ..write('val: $val, ')
          ..write('cif: $cif')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ref, rsoc, activites, adr, logo, capital, rcs,
      nif, stat, tel, port, email, site, fax, telex, tva, t, val, cif);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SocData &&
          other.ref == this.ref &&
          other.rsoc == this.rsoc &&
          other.activites == this.activites &&
          other.adr == this.adr &&
          other.logo == this.logo &&
          other.capital == this.capital &&
          other.rcs == this.rcs &&
          other.nif == this.nif &&
          other.stat == this.stat &&
          other.tel == this.tel &&
          other.port == this.port &&
          other.email == this.email &&
          other.site == this.site &&
          other.fax == this.fax &&
          other.telex == this.telex &&
          other.tva == this.tva &&
          other.t == this.t &&
          other.val == this.val &&
          other.cif == this.cif);
}

class SocCompanion extends UpdateCompanion<SocData> {
  final Value<String> ref;
  final Value<String?> rsoc;
  final Value<String?> activites;
  final Value<String?> adr;
  final Value<String?> logo;
  final Value<double?> capital;
  final Value<String?> rcs;
  final Value<String?> nif;
  final Value<String?> stat;
  final Value<String?> tel;
  final Value<String?> port;
  final Value<String?> email;
  final Value<String?> site;
  final Value<String?> fax;
  final Value<String?> telex;
  final Value<double?> tva;
  final Value<double?> t;
  final Value<String?> val;
  final Value<String?> cif;
  final Value<int> rowid;
  const SocCompanion({
    this.ref = const Value.absent(),
    this.rsoc = const Value.absent(),
    this.activites = const Value.absent(),
    this.adr = const Value.absent(),
    this.logo = const Value.absent(),
    this.capital = const Value.absent(),
    this.rcs = const Value.absent(),
    this.nif = const Value.absent(),
    this.stat = const Value.absent(),
    this.tel = const Value.absent(),
    this.port = const Value.absent(),
    this.email = const Value.absent(),
    this.site = const Value.absent(),
    this.fax = const Value.absent(),
    this.telex = const Value.absent(),
    this.tva = const Value.absent(),
    this.t = const Value.absent(),
    this.val = const Value.absent(),
    this.cif = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SocCompanion.insert({
    required String ref,
    this.rsoc = const Value.absent(),
    this.activites = const Value.absent(),
    this.adr = const Value.absent(),
    this.logo = const Value.absent(),
    this.capital = const Value.absent(),
    this.rcs = const Value.absent(),
    this.nif = const Value.absent(),
    this.stat = const Value.absent(),
    this.tel = const Value.absent(),
    this.port = const Value.absent(),
    this.email = const Value.absent(),
    this.site = const Value.absent(),
    this.fax = const Value.absent(),
    this.telex = const Value.absent(),
    this.tva = const Value.absent(),
    this.t = const Value.absent(),
    this.val = const Value.absent(),
    this.cif = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ref = Value(ref);
  static Insertable<SocData> custom({
    Expression<String>? ref,
    Expression<String>? rsoc,
    Expression<String>? activites,
    Expression<String>? adr,
    Expression<String>? logo,
    Expression<double>? capital,
    Expression<String>? rcs,
    Expression<String>? nif,
    Expression<String>? stat,
    Expression<String>? tel,
    Expression<String>? port,
    Expression<String>? email,
    Expression<String>? site,
    Expression<String>? fax,
    Expression<String>? telex,
    Expression<double>? tva,
    Expression<double>? t,
    Expression<String>? val,
    Expression<String>? cif,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ref != null) 'ref': ref,
      if (rsoc != null) 'rsoc': rsoc,
      if (activites != null) 'activites': activites,
      if (adr != null) 'adr': adr,
      if (logo != null) 'logo': logo,
      if (capital != null) 'capital': capital,
      if (rcs != null) 'rcs': rcs,
      if (nif != null) 'nif': nif,
      if (stat != null) 'stat': stat,
      if (tel != null) 'tel': tel,
      if (port != null) 'port': port,
      if (email != null) 'email': email,
      if (site != null) 'site': site,
      if (fax != null) 'fax': fax,
      if (telex != null) 'telex': telex,
      if (tva != null) 'tva': tva,
      if (t != null) 't': t,
      if (val != null) 'val': val,
      if (cif != null) 'cif': cif,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SocCompanion copyWith(
      {Value<String>? ref,
      Value<String?>? rsoc,
      Value<String?>? activites,
      Value<String?>? adr,
      Value<String?>? logo,
      Value<double?>? capital,
      Value<String?>? rcs,
      Value<String?>? nif,
      Value<String?>? stat,
      Value<String?>? tel,
      Value<String?>? port,
      Value<String?>? email,
      Value<String?>? site,
      Value<String?>? fax,
      Value<String?>? telex,
      Value<double?>? tva,
      Value<double?>? t,
      Value<String?>? val,
      Value<String?>? cif,
      Value<int>? rowid}) {
    return SocCompanion(
      ref: ref ?? this.ref,
      rsoc: rsoc ?? this.rsoc,
      activites: activites ?? this.activites,
      adr: adr ?? this.adr,
      logo: logo ?? this.logo,
      capital: capital ?? this.capital,
      rcs: rcs ?? this.rcs,
      nif: nif ?? this.nif,
      stat: stat ?? this.stat,
      tel: tel ?? this.tel,
      port: port ?? this.port,
      email: email ?? this.email,
      site: site ?? this.site,
      fax: fax ?? this.fax,
      telex: telex ?? this.telex,
      tva: tva ?? this.tva,
      t: t ?? this.t,
      val: val ?? this.val,
      cif: cif ?? this.cif,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (rsoc.present) {
      map['rsoc'] = Variable<String>(rsoc.value);
    }
    if (activites.present) {
      map['activites'] = Variable<String>(activites.value);
    }
    if (adr.present) {
      map['adr'] = Variable<String>(adr.value);
    }
    if (logo.present) {
      map['logo'] = Variable<String>(logo.value);
    }
    if (capital.present) {
      map['capital'] = Variable<double>(capital.value);
    }
    if (rcs.present) {
      map['rcs'] = Variable<String>(rcs.value);
    }
    if (nif.present) {
      map['nif'] = Variable<String>(nif.value);
    }
    if (stat.present) {
      map['stat'] = Variable<String>(stat.value);
    }
    if (tel.present) {
      map['tel'] = Variable<String>(tel.value);
    }
    if (port.present) {
      map['port'] = Variable<String>(port.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (site.present) {
      map['site'] = Variable<String>(site.value);
    }
    if (fax.present) {
      map['fax'] = Variable<String>(fax.value);
    }
    if (telex.present) {
      map['telex'] = Variable<String>(telex.value);
    }
    if (tva.present) {
      map['tva'] = Variable<double>(tva.value);
    }
    if (t.present) {
      map['t'] = Variable<double>(t.value);
    }
    if (val.present) {
      map['val'] = Variable<String>(val.value);
    }
    if (cif.present) {
      map['cif'] = Variable<String>(cif.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SocCompanion(')
          ..write('ref: $ref, ')
          ..write('rsoc: $rsoc, ')
          ..write('activites: $activites, ')
          ..write('adr: $adr, ')
          ..write('logo: $logo, ')
          ..write('capital: $capital, ')
          ..write('rcs: $rcs, ')
          ..write('nif: $nif, ')
          ..write('stat: $stat, ')
          ..write('tel: $tel, ')
          ..write('port: $port, ')
          ..write('email: $email, ')
          ..write('site: $site, ')
          ..write('fax: $fax, ')
          ..write('telex: $telex, ')
          ..write('tva: $tva, ')
          ..write('t: $t, ')
          ..write('val: $val, ')
          ..write('cif: $cif, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SocTable soc = $SocTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [soc];
}

typedef $$SocTableCreateCompanionBuilder = SocCompanion Function({
  required String ref,
  Value<String?> rsoc,
  Value<String?> activites,
  Value<String?> adr,
  Value<String?> logo,
  Value<double?> capital,
  Value<String?> rcs,
  Value<String?> nif,
  Value<String?> stat,
  Value<String?> tel,
  Value<String?> port,
  Value<String?> email,
  Value<String?> site,
  Value<String?> fax,
  Value<String?> telex,
  Value<double?> tva,
  Value<double?> t,
  Value<String?> val,
  Value<String?> cif,
  Value<int> rowid,
});
typedef $$SocTableUpdateCompanionBuilder = SocCompanion Function({
  Value<String> ref,
  Value<String?> rsoc,
  Value<String?> activites,
  Value<String?> adr,
  Value<String?> logo,
  Value<double?> capital,
  Value<String?> rcs,
  Value<String?> nif,
  Value<String?> stat,
  Value<String?> tel,
  Value<String?> port,
  Value<String?> email,
  Value<String?> site,
  Value<String?> fax,
  Value<String?> telex,
  Value<double?> tva,
  Value<double?> t,
  Value<String?> val,
  Value<String?> cif,
  Value<int> rowid,
});

class $$SocTableFilterComposer extends Composer<_$AppDatabase, $SocTable> {
  $$SocTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ref => $composableBuilder(
      column: $table.ref, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rsoc => $composableBuilder(
      column: $table.rsoc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activites => $composableBuilder(
      column: $table.activites, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get adr => $composableBuilder(
      column: $table.adr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logo => $composableBuilder(
      column: $table.logo, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get capital => $composableBuilder(
      column: $table.capital, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rcs => $composableBuilder(
      column: $table.rcs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nif => $composableBuilder(
      column: $table.nif, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stat => $composableBuilder(
      column: $table.stat, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tel => $composableBuilder(
      column: $table.tel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get port => $composableBuilder(
      column: $table.port, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get site => $composableBuilder(
      column: $table.site, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fax => $composableBuilder(
      column: $table.fax, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get telex => $composableBuilder(
      column: $table.telex, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tva => $composableBuilder(
      column: $table.tva, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get t => $composableBuilder(
      column: $table.t, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get val => $composableBuilder(
      column: $table.val, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cif => $composableBuilder(
      column: $table.cif, builder: (column) => ColumnFilters(column));
}

class $$SocTableOrderingComposer extends Composer<_$AppDatabase, $SocTable> {
  $$SocTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ref => $composableBuilder(
      column: $table.ref, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rsoc => $composableBuilder(
      column: $table.rsoc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activites => $composableBuilder(
      column: $table.activites, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get adr => $composableBuilder(
      column: $table.adr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logo => $composableBuilder(
      column: $table.logo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get capital => $composableBuilder(
      column: $table.capital, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rcs => $composableBuilder(
      column: $table.rcs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nif => $composableBuilder(
      column: $table.nif, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stat => $composableBuilder(
      column: $table.stat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tel => $composableBuilder(
      column: $table.tel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get port => $composableBuilder(
      column: $table.port, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get site => $composableBuilder(
      column: $table.site, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fax => $composableBuilder(
      column: $table.fax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get telex => $composableBuilder(
      column: $table.telex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tva => $composableBuilder(
      column: $table.tva, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get t => $composableBuilder(
      column: $table.t, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get val => $composableBuilder(
      column: $table.val, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cif => $composableBuilder(
      column: $table.cif, builder: (column) => ColumnOrderings(column));
}

class $$SocTableAnnotationComposer extends Composer<_$AppDatabase, $SocTable> {
  $$SocTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ref =>
      $composableBuilder(column: $table.ref, builder: (column) => column);

  GeneratedColumn<String> get rsoc =>
      $composableBuilder(column: $table.rsoc, builder: (column) => column);

  GeneratedColumn<String> get activites =>
      $composableBuilder(column: $table.activites, builder: (column) => column);

  GeneratedColumn<String> get adr =>
      $composableBuilder(column: $table.adr, builder: (column) => column);

  GeneratedColumn<String> get logo =>
      $composableBuilder(column: $table.logo, builder: (column) => column);

  GeneratedColumn<double> get capital =>
      $composableBuilder(column: $table.capital, builder: (column) => column);

  GeneratedColumn<String> get rcs =>
      $composableBuilder(column: $table.rcs, builder: (column) => column);

  GeneratedColumn<String> get nif =>
      $composableBuilder(column: $table.nif, builder: (column) => column);

  GeneratedColumn<String> get stat =>
      $composableBuilder(column: $table.stat, builder: (column) => column);

  GeneratedColumn<String> get tel =>
      $composableBuilder(column: $table.tel, builder: (column) => column);

  GeneratedColumn<String> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get site =>
      $composableBuilder(column: $table.site, builder: (column) => column);

  GeneratedColumn<String> get fax =>
      $composableBuilder(column: $table.fax, builder: (column) => column);

  GeneratedColumn<String> get telex =>
      $composableBuilder(column: $table.telex, builder: (column) => column);

  GeneratedColumn<double> get tva =>
      $composableBuilder(column: $table.tva, builder: (column) => column);

  GeneratedColumn<double> get t =>
      $composableBuilder(column: $table.t, builder: (column) => column);

  GeneratedColumn<String> get val =>
      $composableBuilder(column: $table.val, builder: (column) => column);

  GeneratedColumn<String> get cif =>
      $composableBuilder(column: $table.cif, builder: (column) => column);
}

class $$SocTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SocTable,
    SocData,
    $$SocTableFilterComposer,
    $$SocTableOrderingComposer,
    $$SocTableAnnotationComposer,
    $$SocTableCreateCompanionBuilder,
    $$SocTableUpdateCompanionBuilder,
    (SocData, BaseReferences<_$AppDatabase, $SocTable, SocData>),
    SocData,
    PrefetchHooks Function()> {
  $$SocTableTableManager(_$AppDatabase db, $SocTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SocTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SocTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SocTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> ref = const Value.absent(),
            Value<String?> rsoc = const Value.absent(),
            Value<String?> activites = const Value.absent(),
            Value<String?> adr = const Value.absent(),
            Value<String?> logo = const Value.absent(),
            Value<double?> capital = const Value.absent(),
            Value<String?> rcs = const Value.absent(),
            Value<String?> nif = const Value.absent(),
            Value<String?> stat = const Value.absent(),
            Value<String?> tel = const Value.absent(),
            Value<String?> port = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> site = const Value.absent(),
            Value<String?> fax = const Value.absent(),
            Value<String?> telex = const Value.absent(),
            Value<double?> tva = const Value.absent(),
            Value<double?> t = const Value.absent(),
            Value<String?> val = const Value.absent(),
            Value<String?> cif = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SocCompanion(
            ref: ref,
            rsoc: rsoc,
            activites: activites,
            adr: adr,
            logo: logo,
            capital: capital,
            rcs: rcs,
            nif: nif,
            stat: stat,
            tel: tel,
            port: port,
            email: email,
            site: site,
            fax: fax,
            telex: telex,
            tva: tva,
            t: t,
            val: val,
            cif: cif,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String ref,
            Value<String?> rsoc = const Value.absent(),
            Value<String?> activites = const Value.absent(),
            Value<String?> adr = const Value.absent(),
            Value<String?> logo = const Value.absent(),
            Value<double?> capital = const Value.absent(),
            Value<String?> rcs = const Value.absent(),
            Value<String?> nif = const Value.absent(),
            Value<String?> stat = const Value.absent(),
            Value<String?> tel = const Value.absent(),
            Value<String?> port = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> site = const Value.absent(),
            Value<String?> fax = const Value.absent(),
            Value<String?> telex = const Value.absent(),
            Value<double?> tva = const Value.absent(),
            Value<double?> t = const Value.absent(),
            Value<String?> val = const Value.absent(),
            Value<String?> cif = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SocCompanion.insert(
            ref: ref,
            rsoc: rsoc,
            activites: activites,
            adr: adr,
            logo: logo,
            capital: capital,
            rcs: rcs,
            nif: nif,
            stat: stat,
            tel: tel,
            port: port,
            email: email,
            site: site,
            fax: fax,
            telex: telex,
            tva: tva,
            t: t,
            val: val,
            cif: cif,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SocTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SocTable,
    SocData,
    $$SocTableFilterComposer,
    $$SocTableOrderingComposer,
    $$SocTableAnnotationComposer,
    $$SocTableCreateCompanionBuilder,
    $$SocTableUpdateCompanionBuilder,
    (SocData, BaseReferences<_$AppDatabase, $SocTable, SocData>),
    SocData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SocTableTableManager get soc => $$SocTableTableManager(_db, _db.soc);
}
