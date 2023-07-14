local XLottoGroupEntity = XClass(nil, "XLottoGroupEntity")
local XLottoDrawEntity = require("XEntity/XLotto/XLottoDrawEntity")

function XLottoGroupEntity:Ctor(id)
    self.Id = id
    self.CurIndex = 1 --当前逻辑下只可能每一个group中有且仅有一个draw
    self.DrawInfoList = {}
    self.DrawDataDic = {}
end

function XLottoGroupEntity:UpdateData(data)
    for key, value in pairs(data) do
        self[key] = value
    end
    self:CreateDrawDataDic()
end

function XLottoGroupEntity:CreateDrawDataDic()
    self.DrawDataDic = {}
    for _,drawInfo in pairs(self.DrawInfoList) do
        local entity = XLottoDrawEntity.New(drawInfo.Id)
        entity:UpdateData(drawInfo)
        self.DrawDataDic[drawInfo.Id] = entity
    end
end

function XLottoGroupEntity:GetCfg()
    return XLottoConfigs.GetLottoGroupRuleCfgById(self.Id)
end

function XLottoGroupEntity:GetId()
    return self.Id
end

function XLottoGroupEntity:GetDrawData()--当前逻辑下只可能每一个group中有且仅有一个draw
    local id = self.DrawInfoList[self.CurIndex].Id
    return self.DrawDataDic[id]
end

function XLottoGroupEntity:GetName()
    return self:GetCfg().Name
end

function XLottoGroupEntity:GetTag()
    return self:GetCfg().Tag
end

function XLottoGroupEntity:GetPriority()
    return self:GetCfg().Priority
end

function XLottoGroupEntity:GetUiType()
    return self:GetCfg().UiType
end

function XLottoGroupEntity:GetGroupBtnBg()
    return self:GetCfg().GroupBtnBg
end

function XLottoGroupEntity:GetUiPrefab()
    return self:GetCfg().UiPrefab
end

function XLottoGroupEntity:GetBanner()
    local drawData = self:GetDrawData()
    local banner = drawData:GetBanner()
    return banner or self:GetCfg().Banner
end

function XLottoGroupEntity:GetUiBackGround()
    return self:GetCfg().UiBackGround
end

function XLottoGroupEntity:GetRuleHint()
    return self:GetCfg().RuleHint
end

function XLottoGroupEntity:GetBaseRuleTitleList()
    return self:GetCfg().BaseRuleTitles
end

function XLottoGroupEntity:GetBaseRulesList()
    return self:GetCfg().BaseRules
end

return XLottoGroupEntity