---@field _Control XReformControl
---@class XUiReform2ndPanelGroup:XUiNode
local XUiReform2ndPanelGroup = XClass(XUiNode, "XUiReform2ndPanelGroup")

function XUiReform2ndPanelGroup:OnStart(viewModel)
    self._BtnChapters = {}
    ---@type XViewModelReform2nd
    self.ViewModel = viewModel
    self.RedPointList = {}
    self:RegisterClickEvent()
    self.ViewModel:InitChapterList()
end

function XUiReform2ndPanelGroup:SetViewModel(viewModel)
    self.ViewModel = viewModel
end

function XUiReform2ndPanelGroup:RegisterClickEvent()
    local totalNumber = self.ViewModel:GetChapterTotalNumber()
    
    for i = 1, totalNumber do
        local chapter = self.ViewModel:GetChapterByIndex(i)
        local preChapter = nil
        local chapterId = chapter:GetId()

        if i > 1 then
            preChapter = self.ViewModel:GetChapterByIndex(i - 1)
        end
        
        local btn = CS.UnityEngine.Object.Instantiate(self.Btn1, self.Btn1.transform.parent)
        self._BtnChapters[#self._BtnChapters + 1] = btn
        btn.gameObject:SetActiveEx(true)

        XUiHelper.RegisterClickEvent(self, btn, function()
            self:OnBtnGridClick(i)
            self:CloseRedPoint(i)
            XDataCenter.Reform2ndManager.SetChapterRedPointToLocal(chapterId)
        end)
        XRedPointManager.CheckOnce(function(_, count)
            self._BtnChapters[i]:ShowReddot(count >= 0)
        end, self, { XRedPointConditions.Types.CONDITION_REFORM_BASE_STAGE_OPEN }, { Chapter = chapter, PreChapter = preChapter })
        
        ---@type XUiComponent.XUiButton
        local button = btn:GetComponent("XUiButton")
        button:SetRawImage(self.ViewModel:GetChapterImageByIndex(i))
    end
    self.Btn1.gameObject:SetActiveEx(false)
end

function XUiReform2ndPanelGroup:RefreshBtnGrid()
    local viewModel = self.ViewModel
    local model  = self.ViewModel._Model
    local totalNumber = viewModel:GetChapterTotalNumber()

    for i = 1, totalNumber do
        ---@type XReform2ndChapter
        local chapter = viewModel:GetChapterByIndex(i)
        local XUiButtonComponent = self._BtnChapters[i]

        XUiButtonComponent:ShowTag(self._Control:IsChapterFinished(chapter))
        XUiButtonComponent:SetNameByGroup(0, self._Control:GetChapterName(chapter))
        -- todo by zlb
        XUiButtonComponent:SetNameByGroup(1, self._Control:GetChapterStarDesc(chapter))--chapter:GetStarDesc(model)
        XUiButtonComponent:SetNameByGroup(2, viewModel:GetChapterLockedTipByIndex(i))
        XUiButtonComponent:SetDisable(not viewModel:GetChapterIsUnlockedByIndex(i))
    end
end

function XUiReform2ndPanelGroup:OnBtnGridClick(index)
    local isUnlocked = self.ViewModel:GetChapterIsUnlockedByIndex(index)

    if isUnlocked then
        self.ViewModel:SetCurrentChapterIndex(index)
        self.Parent:OpenStagePanel()
    else
        XUiManager.TipMsg(self.ViewModel:GetChapterLockedTipByIndex(index))
    end
end

function XUiReform2ndPanelGroup:CloseRedPoint(index)
    self._BtnChapters[index]:ShowReddot(false)
end

return XUiReform2ndPanelGroup
