--招募界面：底下的布局
local XUiDownPanel = XClass(nil, "XUiDownPanel")

function XUiDownPanel:Ctor(ui, rootUi, adventureChapter, curStep)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    self.RootUi = rootUi
    self.AdventureChapter = adventureChapter
    self.CurStep = curStep
    XTool.InitUiObject(self)
    self:InitBtn()
end

function XUiDownPanel:InitBtn()
    XUiHelper.RegisterClickEvent(self, self.BtnMain, self.OnBtnMainClick)
end

function XUiDownPanel:Refresh()
    --剩余招募次数
    self.TxtRecruitCount.text = self.AdventureChapter:GetRecruitCount()
end

--结束招募
function XUiDownPanel:OnBtnMainClick()
    local adventureChapter = self.AdventureChapter
    local isHaveRole = not XTool.IsTableEmpty(self.CurStep.RecruitCharacterIdDic)
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local leastRecruitCount = XBiancaTheatreConfigs.GetRecruitTicketLeastRecruitCount(adventureManager:GetSelectTickId())
    
    if not adventureChapter:GetIsCanEnterGame() then
        XUiManager.TipText("TheatreRecruitCountHasLeft")
        return
    end

    if adventureChapter:GetRecruitCount() > 0 and isHaveRole and not XTool.IsNumberValid(leastRecruitCount) then
        local title = CS.XTextManager.GetText("TipTitle")
        local content = XBiancaTheatreConfigs.GetClientConfig("UnusedRecruitCountDialogContent")
        local sureCallback = function()
            adventureChapter:RequestEndRecruit()
        end
        XLuaUiManager.Open("UiBiancaTheatreEndTips", title, content, nil, nil, sureCallback)
        return
    end
    
    adventureChapter:RequestEndRecruit()
end

return XUiDownPanel