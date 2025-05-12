---@class XUiPanelLinkCraftActivityStage
---@field private _Control XLinkCraftActivityControl
local XUiPanelLinkCraftActivityStage = XClass(XUiNode, 'XUiPanelLinkCraftActivityStage')
local XUiGridLinkCraftActivityStage = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityChapter/XUiGridLinkCraftActivityStage')

function XUiPanelLinkCraftActivityStage:OnStart(chapterId)
    self._ChapterId = chapterId
    self:InitStageUI()
    self:InitBackground()
    XScheduleManager.ScheduleNextFrame(function()
        self:UpdateStageUI()
        self:FocusOnEnable()
        
        self._FirstEnableEnd = true
    end)
    
end

function XUiPanelLinkCraftActivityStage:OnEnable()
    if self._FirstEnableEnd then
        self:UpdateStageUI()
        self:FocusOnEnable()
    end
end

--region 界面初始化------------->>>
function XUiPanelLinkCraftActivityStage:InitStageUI()
    self.GridChapter.gameObject:SetActiveEx(false)
    --初始化使用的关卡列表模板
    self._UsingPanel = {}
    XTool.InitUiObjectByUi(self._UsingPanel,self['PanelChapter'..self._ChapterId])

    self._UsingPanel.GameObject:SetActiveEx(true)
    
    self._StageGrids = {}
    local stageIds = self._Control:GetStageIdsByChapterId(self._ChapterId)
    for i, Id in ipairs(stageIds) do
        local stageCtrl = XUiGridLinkCraftActivityStage.New(CS.UnityEngine.GameObject.Instantiate(self.GridChapter,self._UsingPanel['Chapter'..i]),self,Id,i)
        table.insert(self._StageGrids, stageCtrl)
        stageCtrl:Open()
    end
end

function XUiPanelLinkCraftActivityStage:InitBackground()
    for i = 1, 10 do
        local bg =  self.Parent['RImgLevelBg'..i]
        if bg then
            if i == self._ChapterId then
                bg.gameObject:SetActiveEx(true)
            else
                bg.gameObject:SetActiveEx(false)
            end
        else
            break
        end
    end
end
--endregion <<<------------------

--region 界面刷新---------------->>>
function XUiPanelLinkCraftActivityStage:UpdateStageUI()
    for i, v in ipairs(self._StageGrids) do
        v:Refresh()
    end
end
--endregion <<<-------------------


--region 事件处理----------------->>>
function XUiPanelLinkCraftActivityStage:FocusOnEnable()
    local stageId = self._Control:GetSelectStageByChapterId(self._ChapterId)
    for i, v in ipairs(self._StageGrids) do
        if v._Id == stageId then
            self.CurGrid = v
            v:FocusUI(true)
            break
        end
    end
end
--endregion <<<-----------------------

return XUiPanelLinkCraftActivityStage