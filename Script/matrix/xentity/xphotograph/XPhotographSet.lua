
local CSVector2 = CS.UnityEngine.Vector2
local CSTxtMgrGetText = CS.XTextManager.GetText

local Alignment = {
    Disable = {
        Value = 0,
        Name = CSTxtMgrGetText("PhotoAlignmentDisable"),
        Anchor = CSVector2(0, 0),
    },
    LT = {
        Value = 1,
        Name = CSTxtMgrGetText("PhotoAlignmentLT"),
        Anchor = CSVector2(0, 1),
    },
    RT = {
        Value = 2,
        Name = CSTxtMgrGetText("PhotoAlignmentRT"),
        Anchor = CSVector2(1, 1),
    },
    LB = {
        Value = 3,
        Name = CSTxtMgrGetText("PhotoAlignmentLB"),
        Anchor = CSVector2(0, 0),
    },
    RB = {
        Value = 4,
        Name = CSTxtMgrGetText("PhotoAlignmentRB"),
        Anchor = CSVector2(1, 0),
    }
}

local Default = {
    _LogoAlignment = Alignment.LT,
    _InfoAlignment = Alignment.RB,
    _OpenLevel = 1,
    _OpenUId = 1
}


local XPhotographSet = XClass(XDataEntityBase, "XPhotographSet")

function XPhotographSet:Ctor()
    self:Init(Default)
end 

function XPhotographSet:Update(logoValue, infoValue, openLv, openUId)
    self:SetProperty("_OpenLevel", openLv)
    self:SetProperty("_OpenUId", openUId)
    
    local oldLogoValue = self:GetProperty("_LogoAlignment").Value
    local oldInfoValue = self:GetProperty("_InfoAlignment").Value
    for key, data in pairs(Alignment or {}) do
        if data.Value == logoValue and logoValue ~= oldLogoValue then
            self:SetProperty("_LogoAlignment", Alignment[key])
        end
        if data.Value == infoValue and infoValue ~= oldInfoValue then
            self:SetProperty("_InfoAlignment", Alignment[key])
        end
    end
end 

function XPhotographSet:GetSampleData()
    return {
        LogoValue = self:GetProperty("_LogoAlignment").Value,
        InfoValue = self:GetProperty("_InfoAlignment").Value,
        OpenLevel = self:GetProperty("_OpenLevel"),
        OpenUId = self:GetProperty("_OpenUId")
    }
end

function XPhotographSet:GetAlignment()
    local list = {}
    for _, data in pairs(Alignment or {}) do
        table.insert(list, data)
    end
    table.sort(list, function(a, b) 
        return a.Value < b.Value
    end)
    return list
end

return XPhotographSet