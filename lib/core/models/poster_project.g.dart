// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poster_project.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPosterProjectCollection on Isar {
  IsarCollection<PosterProject> get posterProjects => this.collection();
}

const PosterProjectSchema = CollectionSchema(
  name: r'PosterProject',
  id: 7987139190888628343,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'exif': PropertySchema(
      id: 1,
      name: r'exif',
      type: IsarType.object,
      target: r'ExifData',
    ),
    r'exported': PropertySchema(
      id: 2,
      name: r'exported',
      type: IsarType.bool,
    ),
    r'exportedImagePath': PropertySchema(
      id: 3,
      name: r'exportedImagePath',
      type: IsarType.string,
    ),
    r'originalImagePath': PropertySchema(
      id: 4,
      name: r'originalImagePath',
      type: IsarType.string,
    )
  },
  estimateSize: _posterProjectEstimateSize,
  serialize: _posterProjectSerialize,
  deserialize: _posterProjectDeserialize,
  deserializeProp: _posterProjectDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {r'ExifData': ExifDataSchema},
  getId: _posterProjectGetId,
  getLinks: _posterProjectGetLinks,
  attach: _posterProjectAttach,
  version: '3.1.0+1',
);

int _posterProjectEstimateSize(
  PosterProject object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 +
      ExifDataSchema.estimateSize(
          object.exif, allOffsets[ExifData]!, allOffsets);
  {
    final value = object.exportedImagePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.originalImagePath.length * 3;
  return bytesCount;
}

void _posterProjectSerialize(
  PosterProject object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeObject<ExifData>(
    offsets[1],
    allOffsets,
    ExifDataSchema.serialize,
    object.exif,
  );
  writer.writeBool(offsets[2], object.exported);
  writer.writeString(offsets[3], object.exportedImagePath);
  writer.writeString(offsets[4], object.originalImagePath);
}

PosterProject _posterProjectDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PosterProject(
    createdAt: reader.readDateTime(offsets[0]),
    exif: reader.readObjectOrNull<ExifData>(
          offsets[1],
          ExifDataSchema.deserialize,
          allOffsets,
        ) ??
        ExifData(),
    exported: reader.readBoolOrNull(offsets[2]) ?? false,
    exportedImagePath: reader.readStringOrNull(offsets[3]),
    originalImagePath: reader.readString(offsets[4]),
  );
  object.id = id;
  return object;
}

P _posterProjectDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readObjectOrNull<ExifData>(
            offset,
            ExifDataSchema.deserialize,
            allOffsets,
          ) ??
          ExifData()) as P;
    case 2:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _posterProjectGetId(PosterProject object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _posterProjectGetLinks(PosterProject object) {
  return [];
}

void _posterProjectAttach(
    IsarCollection<dynamic> col, Id id, PosterProject object) {
  object.id = id;
}

extension PosterProjectQueryWhereSort
    on QueryBuilder<PosterProject, PosterProject, QWhere> {
  QueryBuilder<PosterProject, PosterProject, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PosterProjectQueryWhere
    on QueryBuilder<PosterProject, PosterProject, QWhereClause> {
  QueryBuilder<PosterProject, PosterProject, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PosterProjectQueryFilter
    on QueryBuilder<PosterProject, PosterProject, QFilterCondition> {
  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exported',
        value: value,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'exportedImagePath',
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'exportedImagePath',
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exportedImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exportedImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exportedImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exportedImagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exportedImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exportedImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exportedImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exportedImagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exportedImagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      exportedImagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exportedImagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      originalImagePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      originalImagePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      originalImagePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      originalImagePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalImagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      originalImagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'originalImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      originalImagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'originalImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      originalImagePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'originalImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      originalImagePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'originalImagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      originalImagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalImagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition>
      originalImagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'originalImagePath',
        value: '',
      ));
    });
  }
}

extension PosterProjectQueryObject
    on QueryBuilder<PosterProject, PosterProject, QFilterCondition> {
  QueryBuilder<PosterProject, PosterProject, QAfterFilterCondition> exif(
      FilterQuery<ExifData> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'exif');
    });
  }
}

extension PosterProjectQueryLinks
    on QueryBuilder<PosterProject, PosterProject, QFilterCondition> {}

extension PosterProjectQuerySortBy
    on QueryBuilder<PosterProject, PosterProject, QSortBy> {
  QueryBuilder<PosterProject, PosterProject, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy> sortByExported() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exported', Sort.asc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      sortByExportedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exported', Sort.desc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      sortByExportedImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exportedImagePath', Sort.asc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      sortByExportedImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exportedImagePath', Sort.desc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      sortByOriginalImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalImagePath', Sort.asc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      sortByOriginalImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalImagePath', Sort.desc);
    });
  }
}

extension PosterProjectQuerySortThenBy
    on QueryBuilder<PosterProject, PosterProject, QSortThenBy> {
  QueryBuilder<PosterProject, PosterProject, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy> thenByExported() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exported', Sort.asc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      thenByExportedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exported', Sort.desc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      thenByExportedImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exportedImagePath', Sort.asc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      thenByExportedImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exportedImagePath', Sort.desc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      thenByOriginalImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalImagePath', Sort.asc);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QAfterSortBy>
      thenByOriginalImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalImagePath', Sort.desc);
    });
  }
}

extension PosterProjectQueryWhereDistinct
    on QueryBuilder<PosterProject, PosterProject, QDistinct> {
  QueryBuilder<PosterProject, PosterProject, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PosterProject, PosterProject, QDistinct> distinctByExported() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exported');
    });
  }

  QueryBuilder<PosterProject, PosterProject, QDistinct>
      distinctByExportedImagePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exportedImagePath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosterProject, PosterProject, QDistinct>
      distinctByOriginalImagePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalImagePath',
          caseSensitive: caseSensitive);
    });
  }
}

extension PosterProjectQueryProperty
    on QueryBuilder<PosterProject, PosterProject, QQueryProperty> {
  QueryBuilder<PosterProject, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PosterProject, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PosterProject, ExifData, QQueryOperations> exifProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exif');
    });
  }

  QueryBuilder<PosterProject, bool, QQueryOperations> exportedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exported');
    });
  }

  QueryBuilder<PosterProject, String?, QQueryOperations>
      exportedImagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exportedImagePath');
    });
  }

  QueryBuilder<PosterProject, String, QQueryOperations>
      originalImagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalImagePath');
    });
  }
}
