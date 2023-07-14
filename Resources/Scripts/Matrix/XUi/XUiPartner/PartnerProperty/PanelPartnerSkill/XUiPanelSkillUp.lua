local XUiPanelSkillUp = XClass(nil, "XUiPanelSkillUp")
local XUiGridSkillUp = require("XUi/XUiPartner/PartnerProperty/PanelPartnerSkill/XUiGridSkillUp")
local XUiGridCostItem = require("XUi/XUiEquipBreakThrough/XUiGridCostItem")
local Vector3 = CS.UnityEngine.Vector3
local DefaultIndex = 1
local DefaultCount = 1
local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("0E70BDFF"),
    [false] = CS.UnityEngine.Color.gray,
}

function XUiPanelSkillUp:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.IsPlayingAnim = false
    self.SkillIdToIndexDic = {}
    self:InitPanelSkill()
    self:InitPanelCost()
end

function XUiPanelSkillUp:InitPanelSkill()
    self.PassiveSkillPos = {
        self.PassiveSkillPos1,
        self.PassiveSkillPos2,
        self.PassiveSkillPos3,
        self.PassiveSkillPos4,
        self.PassiveSkillPos5,
    }
    self.GridMainSkill.gameObject:SetActiveEx(false)
    self.GridPassiveSkill.gameObject:SetActiveEx(false)
    self.MainSkill = nil
    self.PassiveSkillList = {}
end

function XUiPanelSkillUp:InitPanelCost()
    self.GridCostItems = {}
    self.GridCostItem.gameObject:SetActiveEx(false)
end

function XUiPanelSkillUp:SetButtonCallBack()
    self.BtnSkillUp.CallBack = function()
        self:OnBtnSkillUpClick()
    end
    
    self.BtnSkillUpAll.CallBack = function()
        self:OnBtnSkillUpAllClick()
    end
end

function XUiPanelSkillUp:UpdatePanel(data)
    self.Data = data
    self.GameObject:SetActiveEx(true)

    if not self.IsPlayingAnim then
        self:UpdatePanelSkill(data)
        self:UpdatePanelCost(data)
    end
end

function XUiPanelSkillUp:UpdatePanelSkill(data)
    local mainSkillGroupList = data:GetMainSkillGroupList()
    local passiveSkillEntityDic = data:GetPassiveSkillGroupEntityDic()

    for _,entity in pairs(mainSkillGroupList or {}) do--主技能共享技能等级，此处只显示装备中的主技能
        if entity:GetIsCarry() then
            if not self.MainSkill then
                local obj = CS.UnityEngine.Object.Instantiate(self.GridMainSkill, self.MainSkillPos)
                obj.gameObject:SetActiveEx(true)
                obj.transform.localPosition = Vector3.zero
                self.MainSkill = XUiGridSkillUp.New(obj, self)
            end
            self.MainSkill:UpdateGrid(entity, mainSkillGroupList, XPartnerConfigs.SkillType.MainSkill)
            self.SkillIdToIndexDic[entity:GetActiveSkillId()] = DefaultIndex
            break
        end
    end

    local posindex = 1
    local skillIndex = 1
    for _,entity in pairs(passiveSkillEntityDic or {}) do
        local skillPos = self.PassiveSkillPos[posindex]
        if skillPos then
            local skill = self.PassiveSkillList[skillIndex]
            if not skill then
                local obj = CS.UnityEngine.Object.Instantiate(self.GridPassiveSkill, skillPos)
                obj.gameObject:SetActiveEx(true)
                obj.transform.localPosition = Vector3.zero
                skill = XUiGridSkillUp.New(obj, self)
                self.PassiveSkillList[skillIndex] = skill
            end
            skill:UpdateGrid(entity, nil, XPartnerConfigs.SkillType.PassiveSkill)
            skillIndex = skillIndex + 1
            self.SkillIdToIndexDic[entity:GetActiveSkillId()] = posindex + 1
        end
        posindex = posindex + 1
    end

    for index = skillIndex, #self.PassiveSkillPos do
        self.PassiveSkillPos[index].gameObject:SetActiveEx(false)
    end
end

function XUiPanelSkillUp:UpdatePanelCost(data)
    local costMoney = data:GetSkillUpgradeMoney().Count
    self.PanelCost:GetObject("CostCount").text = costMoney
    self.PanelCost:GetObject("CostCount").color = CONDITION_COLOR[XDataCenter.ItemManager.GetCoinsNum() >= costMoney]
    self.PanelCost.gameObject:SetActiveEx(costMoney > 0)

    local consumeItems = data:GetSkillUpgradeItem()
    for index,item in pairs(consumeItems)do
        local grid = self.GridCostItems[index]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridCostItem, self.PanelCostItem)
            grid = XUiGridCostItem.New(self.Root, obj)
            self.GridCostItems[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(item.Id, item.Count)
    end

    for i = #consumeItems + 1, #self.GridCostItems do
        self.GridCostItems[i].GameObject:SetActiveEx(false)
    end
end

function XUiPanelSkillUp:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelSkillUp:PlayEnableAnime()
    if not self.IsPlayingAnim then
        XScheduleManager.ScheduleOnce(function()
                XLuaUiManager.SetMask(true)
                self.SkillUpEnable.gameObject:PlayTimelineAnimation(function ()
                        XLuaUiManager.SetMask(false)
                    end)
                self.PassiveSkillPosLoop.gameObject:SetActiveEx(false)
                self.PassiveSkillPosLoop.gameObject:SetActiveEx(true)
            end, 1)
    end
end

function XUiPanelSkillUp:OnBtnSkillUpClick()
    if self.IsPlayingAnim then
        return
    end
    self.IsPlayingAnim = true
    local animeCb = function(skillUpInfo)
        self.IsPlayingAnim = false
        self.Base:SetSkillUpFinish(true)
        self.Base:SetSkillUpInfo(skillUpInfo)
        self.Base:UpdatePanel(self.Data)
    end
    
    XDataCenter.PartnerManager.PartnerSkillUpRequest(self.Data:GetId(), DefaultCount, function (skillUpInfo)
            local skillId = skillUpInfo[DefaultIndex].SkillId
            self:PlayAnime(skillId, function ()
                    animeCb(skillUpInfo)
                end)
        end, function ()
            self.IsPlayingAnim = false
        end)
end

function XUiPanelSkillUp:OnBtnSkillUpAllClick()
    XLuaUiManager.Open("UiPartnerSkillLevelUpAll", self.Data, self, self.Base)
end

function XUiPanelSkillUp:PlayAnime(skillId, cb)
    local index = self.SkillIdToIndexDic[skillId]
    if index then
        self.Base.AnimationControlPanel:PlaySkillUpAnime(index ,cb)
    else
        if cb then cb() end
    end
end

function XUiPanelSkillUp:PlaySelectAnime(skillId, cb)
    local index = self.SkillIdToIndexDic[skillId]
    if index then
        self.Base.AnimationControlPanel:PlaySelectAnime(index ,cb)
    else
        if cb then cb() end
    end
end

return XUiPanelSkillUp