ITEM.name = "Medium-sized Bag"
ITEM.desc = "A medium-sized bag capable of holding some items."
ITEM.model = "models/fallout 3/backpack_2.mdl"
ITEM.bagUniqueID = 2
ITEM.width = 3
ITEM.height = 3
ITEM.invWidth = 5
ITEM.invHeight = 5
ITEM.flag = "Y"
ITEM.price = 1900

if (CLIENT) then
    util.PrecacheModel( ITEM.model )
end