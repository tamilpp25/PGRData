local tableInsert = table.insert

XChristmasTreeConfig = XChristmasTreeConfig or {}

local CHRISTMAS_TREE_ACTIVITY_PATH = "Share/MiniActivity/ChristmasTree/ChristmasTree.tab"
local CHRISTMAS_TREE_ACTIVITY_ORNAMENT_PATH = "Share/MiniActivity/ChristmasTree/ChristmasTreeOrnaments.tab"
local CHRISTMAS_TREE_ACTIVITY_PART_PATH = "Share/MiniActivity/ChristmasTree/ChristmasTreePart.tab"

local ActivityTemplates = {}
local ChristmasTreeOrnament = {}
local ChristmasTreeOrnamentGroup = {}
local ChristmasTreePart = {}
local ChristmasTreePartGroup = {}
local OrnamentAttrCount = {}
local PartCount, PartGrpCount

function XChristmasTreeConfig.Init()
    ActivityTemplates = XTableManager.ReadByIntKey(CHRISTMAS_TREE_ACTIVITY_PATH, XTable.XTableChristmasTreeActivity, "Id")
    
    ChristmasTreePart = XTableManager.ReadByIntKey(CHRISTMAS_TREE_ACTIVITY_PART_PATH, XTable.XTableChristmasTreeActivityPart, "Id")
    PartCount, PartGrpCount = 0, 0
    for _, item in ipairs(ChristmasTreePart) do
        if not ChristmasTreePartGroup[item.GroupId] then
            PartGrpCount = PartGrpCount + 1
            ChristmasTreePartGroup[item.GroupId] = {}
        end
        tableInsert(ChristmasTreePartGroup[item.GroupId], item)
        PartCount = PartCount + 1
    end
    
    ChristmasTreeOrnament = XTableManager.ReadByIntKey(CHRISTMAS_TREE_ACTIVITY_ORNAMENT_PATH, XTable.XTableChristmasTreeActivityOrnament, "Id")
    for _, item in ipairs(ChristmasTreeOrnament) do
        OrnamentAttrCount[item.Id] = 0
        for _, value in ipairs(item.Attr) do
            OrnamentAttrCount[item.Id] = OrnamentAttrCount[item.Id] + value
        end
        for _, partId in ipairs(item.PartId) do
            local groupId = XChristmasTreeConfig.GetGrpIdByTreePart(partId)
            if not ChristmasTreeOrnamentGroup[groupId] then
                ChristmasTreeOrnamentGroup[groupId] = {}
            end
            if not ChristmasTreeOrnamentGroup[groupId][item.Id] then
                ChristmasTreeOrnamentGroup[groupId][item.Id] = item
            end
        end
    end
end

function XChristmasTreeConfig.GetActivityTemplates()
    return ActivityTemplates
end

function XChristmasTreeConfig.GetActivityTemplateById(Id)
    if not ActivityTemplates then
        return nil
    end

    return ActivityTemplates[Id]
end

function XChristmasTreeConfig.GetOrnamentCfg()
    return ChristmasTreeOrnament
end

function XChristmasTreeConfig.GetOrnamentById(id)
    return ChristmasTreeOrnament[id]
end

function XChristmasTreeConfig.GetOrnamentByGroup(grpId)
    return ChristmasTreeOrnamentGroup[grpId]
end

function XChristmasTreeConfig.GetTreePartCount()
    return PartCount, PartGrpCount
end

function XChristmasTreeConfig.GetAttrCount(id)
    return OrnamentAttrCount[id]
end

function XChristmasTreeConfig.GetTreePartById(id)
    return ChristmasTreePart[id]
end

function XChristmasTreeConfig.GetGrpIdByTreePart(id)
    return ChristmasTreePart[id].GroupId
end

function XChristmasTreeConfig.GetTreePartByGroup(grpId)
    return ChristmasTreePartGroup[grpId]
end