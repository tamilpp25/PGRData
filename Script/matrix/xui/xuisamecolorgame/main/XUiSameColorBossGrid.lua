---@class XUiSameColorBossGrid:XUiNode
---@field _Control XSameColorControl
local XUiSameColorBossGrid = XClass(XUiNode, "XUiSameColorBossGrid")

function XUiSameColorBossGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    self.Boss = nil
    self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
    self.Index = 0
end

---@param boss XSCBoss
function XUiSameColorBossGrid:SetData(boss, index)
    self.Boss = boss
    self.Index = index
    self.TxtName.text = boss:GetName()
    self.TxtName2.text = boss:GetName()
    local maxScore = boss:GetMaxScore()
    self.RImgGrade:SetRawImage(boss:GetMaxGradeIcon())
    self.RImgGrade2:SetRawImage(boss:GetMaxGradeIcon())
    self.RImgIcon:SetRawImage(boss:GetFullBodyIcon())
    self.RImgIcon2:SetRawImage(boss:GetFullBodyIcon())
    self.RImgLock:SetRawImage(boss:GetFullBodyIcon())
    local showGradeInfo = self.Boss:GetIsOpen() and maxScore > 0
    -- 5期名字底图也要隐藏，不想加引用直接父节点处理了
    self.TxtName.transform.parent.gameObject:SetActiveEx(not showGradeInfo)
    self.TxtName2.transform.parent.gameObject:SetActiveEx(not showGradeInfo)
    self.TxtMaxScore.gameObject:SetActiveEx(showGradeInfo)
    self.TxtMaxScore2.gameObject:SetActiveEx(showGradeInfo)
    self.RImgGrade.gameObject:SetActiveEx(showGradeInfo)
    self.RImgGrade2.gameObject:SetActiveEx(showGradeInfo)
    if showGradeInfo then
        self.TxtMaxCombo.text = boss:GetMaxCombo()
        self.TxtMaxCombo2.text = boss:GetMaxCombo()
        self.TxtMaxScore.text = XUiHelper.GetText("SCBossMaxScoreText", maxScore)
        self.TxtMaxScore2.text = XUiHelper.GetText("SCBossMaxScoreText", maxScore)
    end
    local isTimeType = boss:IsTimeType()
    self.PanelLabel.gameObject:SetActiveEx(isTimeType)
    self:RefreshStatus()
end

function XUiSameColorBossGrid:RefreshStatus()
    local isOpen, desc = self.Boss:GetIsOpen()
    self.PanelLock.gameObject:SetActiveEx(not isOpen)
    if not isOpen then
        self.TxtLockTip.text = desc
    end
end

function XUiSameColorBossGrid:OnBtnSelfClicked()
    local isOpen, desc = self.Boss:GetIsOpen()
    if not isOpen then
        XUiManager.TipError(desc)
        return
    end
    XLuaUiManager.Open("UiSameColorGameBoss", self.Boss)
end

return XUiSameColorBossGrid