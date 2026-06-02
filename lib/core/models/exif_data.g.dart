// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exif_data.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ExifDataSchema = Schema(
  name: r'ExifData',
  id: -4836522593138243196,
  properties: {
    r'aperture': PropertySchema(
      id: 0,
      name: r'aperture',
      type: IsarType.string,
    ),
    r'cameraMake': PropertySchema(
      id: 1,
      name: r'cameraMake',
      type: IsarType.string,
    ),
    r'cameraName': PropertySchema(
      id: 2,
      name: r'cameraName',
      type: IsarType.string,
    ),
    r'focalLength': PropertySchema(
      id: 3,
      name: r'focalLength',
      type: IsarType.string,
    ),
    r'iso': PropertySchema(
      id: 4,
      name: r'iso',
      type: IsarType.string,
    ),
    r'lensModel': PropertySchema(
      id: 5,
      name: r'lensModel',
      type: IsarType.string,
    ),
    r'location': PropertySchema(
      id: 6,
      name: r'location',
      type: IsarType.string,
    ),
    r'shotDate': PropertySchema(
      id: 7,
      name: r'shotDate',
      type: IsarType.dateTime,
    ),
    r'shutterSpeed': PropertySchema(
      id: 8,
      name: r'shutterSpeed',
      type: IsarType.string,
    )
  },
  estimateSize: _exifDataEstimateSize,
  serialize: _exifDataSerialize,
  deserialize: _exifDataDeserialize,
  deserializeProp: _exifDataDeserializeProp,
);

int _exifDataEstimateSize(
  ExifData object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.aperture;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.cameraMake;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.cameraName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.focalLength;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.iso;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lensModel;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.location;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.shutterSpeed;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _exifDataSerialize(
  ExifData object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.aperture);
  writer.writeString(offsets[1], object.cameraMake);
  writer.writeString(offsets[2], object.cameraName);
  writer.writeString(offsets[3], object.focalLength);
  writer.writeString(offsets[4], object.iso);
  writer.writeString(offsets[5], object.lensModel);
  writer.writeString(offsets[6], object.location);
  writer.writeDateTime(offsets[7], object.shotDate);
  writer.writeString(offsets[8], object.shutterSpeed);
}

ExifData _exifDataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExifData(
    aperture: reader.readStringOrNull(offsets[0]),
    cameraMake: reader.readStringOrNull(offsets[1]),
    cameraName: reader.readStringOrNull(offsets[2]),
    focalLength: reader.readStringOrNull(offsets[3]),
    iso: reader.readStringOrNull(offsets[4]),
    lensModel: reader.readStringOrNull(offsets[5]),
    location: reader.readStringOrNull(offsets[6]),
    shotDate: reader.readDateTimeOrNull(offsets[7]),
    shutterSpeed: reader.readStringOrNull(offsets[8]),
  );
  return object;
}

P _exifDataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ExifDataQueryFilter
    on QueryBuilder<ExifData, ExifData, QFilterCondition> {
  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aperture',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aperture',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aperture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aperture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aperture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aperture',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aperture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aperture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aperture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aperture',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aperture',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> apertureIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aperture',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraMakeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cameraMake',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      cameraMakeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cameraMake',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraMakeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cameraMake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraMakeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cameraMake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraMakeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cameraMake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraMakeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cameraMake',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraMakeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cameraMake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraMakeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cameraMake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraMakeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cameraMake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraMakeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cameraMake',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraMakeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cameraMake',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      cameraMakeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cameraMake',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cameraName',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      cameraNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cameraName',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cameraName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cameraName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cameraName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cameraName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cameraName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cameraName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cameraName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cameraName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> cameraNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cameraName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      cameraNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cameraName',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> focalLengthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'focalLength',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      focalLengthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'focalLength',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> focalLengthEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'focalLength',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      focalLengthGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'focalLength',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> focalLengthLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'focalLength',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> focalLengthBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'focalLength',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> focalLengthStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'focalLength',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> focalLengthEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'focalLength',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> focalLengthContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'focalLength',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> focalLengthMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'focalLength',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> focalLengthIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'focalLength',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      focalLengthIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'focalLength',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'iso',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'iso',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'iso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'iso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'iso',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'iso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'iso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'iso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'iso',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iso',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> isoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'iso',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> lensModelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lensModel',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> lensModelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lensModel',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> lensModelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lensModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> lensModelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lensModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> lensModelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lensModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> lensModelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lensModel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> lensModelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lensModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> lensModelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lensModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> lensModelContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lensModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> lensModelMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lensModel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> lensModelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lensModel',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      lensModelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lensModel',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'location',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'location',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'location',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'location',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'location',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> locationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'location',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shotDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'shotDate',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shotDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'shotDate',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shotDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shotDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shotDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shotDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shotDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shotDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shotDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shotDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shutterSpeedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'shutterSpeed',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      shutterSpeedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'shutterSpeed',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shutterSpeedEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shutterSpeed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      shutterSpeedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shutterSpeed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shutterSpeedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shutterSpeed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shutterSpeedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shutterSpeed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      shutterSpeedStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'shutterSpeed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shutterSpeedEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'shutterSpeed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shutterSpeedContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'shutterSpeed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition> shutterSpeedMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'shutterSpeed',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      shutterSpeedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shutterSpeed',
        value: '',
      ));
    });
  }

  QueryBuilder<ExifData, ExifData, QAfterFilterCondition>
      shutterSpeedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'shutterSpeed',
        value: '',
      ));
    });
  }
}

extension ExifDataQueryObject
    on QueryBuilder<ExifData, ExifData, QFilterCondition> {}
