/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2616095987")

  // add field
  collection.fields.addAt(7, new Field({
    "hidden": false,
    "id": "date1911152639",
    "max": "",
    "min": "",
    "name": "clock_out_time",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "date"
  }))

  // add field
  collection.fields.addAt(8, new Field({
    "hidden": false,
    "id": "number647814720",
    "max": null,
    "min": null,
    "name": "clock_out_latitude",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(9, new Field({
    "hidden": false,
    "id": "number1363008390",
    "max": null,
    "min": null,
    "name": "clock_out_longitude",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_2616095987")

  // remove field
  collection.fields.removeById("date1911152639")

  // remove field
  collection.fields.removeById("number647814720")

  // remove field
  collection.fields.removeById("number1363008390")

  return app.save(collection)
})
