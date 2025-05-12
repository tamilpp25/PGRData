---@class XUiLinkCraftActivityChapterDetail
---@field private _Control XLinkCraftActivityControl
local XUiLinkCraftActivityChapterDetail = XLuaUiManager.Register(XLuaUi, 'UiLinkCraftActivityChapterDetail')

local BattleRoleRoomProxy = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityBattleRoleRoom/XUiLinkCraftActivityBattleRoleRoom')
local XUiGridLinkCraftActivityChapterDetailAffix = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityChapterDetail/XUiGridLinkCraftActivityChapterDetailAffix')
local XUiGridLinkCraftActivityItem = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityChapterDetail/XUiGridLinkCraftActivityItem')
local XUiPanelLinkCraftActivitySkillReward = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityChapterDetail/XUiPanelLinkCraftActivitySkillReward')
local XUiGridLinkCraftActivityTarget = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityChapterDetail/XUiGridLinkCraftActivityTarget')

function XUiLinkCraftActivityChapterDetail:OnStart(_id,_index)
    self._Id = _id
    self._Index = _index
    self._StageId = self._Control:GetStageIdById(self._Id)
    self.BtnClose.CallBack = handler(self,self.Close)
    self.BtnEnter.CallBack = handler(self,self.OnBtnEnterClickEvent)
    self:Init()
end

function XUiLinkCraftActivityChapterDetail:OnEnable()
    if XTool.IsNumberValid(self._Id) and XTool.IsNumberValid(self._Index) then
        self:Refresh()
    end
end

function XUiLinkCraftActivityChapterDetail:Init()
    self.TxtTitle.text = XDataCenter.FubenManager.GetStageName(self._StageId)
    --初始化词缀
    self._GridAffixCtrl = {}
    
    local index = 1
    local grid = nil
    repeat
        grid = self['GridAffix'..index]

        if grid then
            local affixGridCtrl = XUiGridLinkCraftActivityChapterDetailAffix.New(grid, self)
            table.insert(self._GridAffixCtrl, affixGridCtrl)
        end
        index = index + 1
        
    until grid ==nil or index > 10000
    
    self._RewardSkillPanel = XUiPanelLinkCraftActivitySkillReward.New(self.GridSkill,self)
    self._RewardSkillPanel:Close()
end

function XUiLinkCraftActivityChapterDetail:Refresh()
    --刷新词缀
    local affixIcons = self._Control:GetStageAffixIconById(self._Id)
    local affixDesc = self._Control:GetStageAffixDescById(self._Id)

    for i, v in ipairs(self._GridAffixCtrl) do
        if not string.IsNilOrEmpty(affixIcons[i]) or not string.IsNilOrEmpty(affixDesc[i]) then
            v:Open()
            v:Refresh(affixIcons[i],affixDesc[i])
        else
            v:Close()
        end
    end

    --刷新奖励
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self._StageId)
    if XTool.GetTableCount(stageCfg.StarRewardId) > 0 then
        self:RefreshTargetList(stageCfg)
    else
        self:RefreshDropList(stageCfg)
    end
end

function XUiLinkCraftActivityChapterDetail:RefreshDropList(stageCfg)
    self.PanelDropList.gameObject:SetActiveEx(true)
    self.PanelTargetList.gameObject:SetActiveEx(false)
    
    self.GridCommon.gameObject:SetActiveEx(false)
    local totalItems = {}
    local skillId = self._Control:GetStageSkillRewardById(self._Id)
    local linkId = self._Control:GetStageLinkRewardById(self._Id)
    table.insert(totalItems, XTool.IsNumberValid(skillId) and skillId or nil)
    table.insert(totalItems, XTool.IsNumberValid(linkId) and linkId or nil)
    local commonItems = XRewardManager.GetRewardList(stageCfg.FirstRewardId)
    if not XTool.IsTableEmpty(commonItems) then
        for i, v in ipairs(commonItems) do
            table.insert(totalItems, v)
        end
    end

    local specialType = {}
    table.insert(specialType, XTool.IsNumberValid(skillId) and XEnumConst.LinkCraftActivity.GoodsSpecialType.Skill or nil)
    table.insert(specialType, XTool.IsNumberValid(linkId) and XEnumConst.LinkCraftActivity.GoodsSpecialType.Link or nil)

    XUiHelper.RefreshCustomizedList(self.PanelDropContent, self.GridCommon, totalItems and #totalItems or 0, function(index, obj)
        local gridCommont = XUiGridLinkCraftActivityItem.New(self, obj)
        gridCommont:Refresh(specialType[index],totalItems[index])

        local linkStageId = XMVCA.XLinkCraftActivity:GetStageIdOfLinkStageTabById(self._StageId)

        gridCommont:SetReceived(XMVCA.XLinkCraftActivity:CheckStageIsPassById(linkStageId))
    end)
end

function XUiLinkCraftActivityChapterDetail:RefreshTargetList(stageCfg)
    self.PanelDropList.gameObject:SetActiveEx(false)
    self.PanelTargetList.gameObject:SetActiveEx(true)

    for i = 1, 10 do
        local grid = self['GridTarget'..i]
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
    
    for i, v in ipairs(stageCfg.StarDesc) do
        local go = self['GridTarget'..i]
        local grid = XUiGridLinkCraftActivityTarget.New(go,self,i)
        grid:Open()
        grid:Refresh(self._Id, stageCfg.StarRewardId[i], v)
    end
    
end

function XUiLinkCraftActivityChapterDetail:OpenSkillRewardDetail(skillId)
    self._RewardSkillPanel:Open()
    self._RewardSkillPanel:Refresh(skillId)
end

function XUiLinkCraftActivityChapterDetail:CloseSkillRewardDetail()
    self._RewardSkillPanel:Close()
end 

function XUiLinkCraftActivityChapterDetail:OnBtnEnterClickEvent()
    XLuaUiManager.Open("UiBattleRoleRoom",self._StageId,self._Control:GetLocalTeam(),BattleRoleRoomProxy)
    -- 需要缓存当前选择的关卡
    self._Control:SetSelectedStageId(self._Id)
end

function XUiLinkCraftActivityChapterDetail:Close()
    if self._RewardSkillPanel:IsNodeShow() then
        self:CloseSkillRewardDetail()
    else
        self.Super.Close(self)
    end
end

return XUiLinkCraftActivityChapterDetail