---@class XUiLinkCraftActivityChapter
---@field private _Control XLinkCraftActivityControl
local XUiLinkCraftActivityChapter = XLuaUiManager.Register(XLuaUi, 'UiLinkCraftActivityChapter')
local XUiPanelLinkCraftActivityStage = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityChapter/XUiPanelLinkCraftActivityStage')
local XUiPanelLinkCraftActivityLink = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityChapter/XUiPanelLinkCraftActivityLink')

--region 生命周期--------------->>>
function XUiLinkCraftActivityChapter:OnAwake()
    self.BtnBack.CallBack = handler(self,self.Close)
    self.BtnMainUi.CallBack = function()
        self._Control:SetLastSelectChapterId(self._ChapterId)
        self._Control:SetCurChapterById(nil)
        XLuaUiManager.RunMain()
    end
    self:BindHelpBtn(self.BtnHelp,'LinkCraftActivity')
end

function XUiLinkCraftActivityChapter:OnStart(chapterId)
    local leftTime = XMVCA.XLinkCraftActivity:GetLeftTime()
    --到点踢出
    if leftTime <= 0 then
        return
    end
    
    self._ChapterId = chapterId
    self._Control:SetCurChapterById(self._ChapterId)
    self._Control:MarkChapterIsOld(self._ChapterId)
    self:InitTitle()
    self:InitStageUI()
    self:InitLinkListUI()
end

function XUiLinkCraftActivityChapter:OnEnable()
    local leftTime = XMVCA.XLinkCraftActivity:GetLeftTime()
    --到点踢出
    if leftTime <= 0 then
        return
    end
    
    self:CheckHasNewSkillUnLock()
end

function XUiLinkCraftActivityChapter:Close()
    self._Control:SetLastSelectChapterId(self._ChapterId)
    self._Control:SetCurChapterById(nil)
    self.Super.Close(self)
end
--endregion <<<-------------------

--region 界面初始化--------------->>>
function XUiLinkCraftActivityChapter:InitTitle()
    self.TxtTitle = self._Control:GetChapterNameById(self._ChapterId)
end

function XUiLinkCraftActivityChapter:InitStageUI()
    self._PanelStage = XUiPanelLinkCraftActivityStage.New(self.ListChapter, self, self._ChapterId)
    self._PanelStage:Open()
end

function XUiLinkCraftActivityChapter:InitLinkListUI()
    self._PanelLink = XUiPanelLinkCraftActivityLink.New(self.PanelLinkFore,self)
    self._PanelLink:Open()
end
--endregion <<<-------------------

function XUiLinkCraftActivityChapter:CheckHasNewSkillUnLock()
    local newSkills = self._Control:GetNewSkill()
    if not XTool.IsTableEmpty(newSkills) then
        for i, v in ipairs(newSkills) do
            local pattern = self._Control:GetClientConfigString('NewSkillTips')
            local content = XUiHelper.FormatText(pattern, self._Control:GetSkillNameById(v))
            XUiManager.TipMsgEnqueue(content)
        end
        self._Control:ClearNewSkillMark()
        XUiManager.TipMsgDequeue()
    end
end

return XUiLinkCraftActivityChapter