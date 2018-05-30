## JSON format

### In case of a error:
```json
{
  "error": "error message"
}
```
along with HTTP response status set accordingly

### A single record
```json
{
  "record.class.to_s.underscore": {
    "id": "a_string",
    "updated_at": "time stamp, required at several places",
    "further_properties": "at will"
  }
}
```

### A relation
```json
{
  "record.class.to_s.underscore": {
    "id": "a_string",
    "relation_name": [
      {
        "member_record.class.to_s.underscore": {
          "id": "a_string",
          "further_properties": "at_will"
        }
      },
      // further records ...
    ]
  }
}
```

### A scope
```json
{
  "record.class.to_s.underscore": {
    "scope_name": [
      {
        "member_record.class.to_s.underscore": {
          "id": "a_string",
          "further_properties": "at_will"
        }
      },
      // further records ...
    ]
  }
}
```

### A rest_method or a rest_class_method
```json
{
  "result": result_value_or_object
}
```