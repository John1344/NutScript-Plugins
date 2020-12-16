ITEM.name = "Large Bag"
ITEM.desc = "A big bag capable of holding a lot of items."
ITEM.model = "models/fallout 3/backpack_6.mdl"
ITEM.bagUniqueID = 3
ITEM.width = 3
ITEM.height = 4
ITEM.invWidth = 5
ITEM.invHeight = 6
ITEM.flag = "Y"
ITEM.price = 2900

if (CLIENT) then
    util.PrecacheModel( ITEM.model )
end