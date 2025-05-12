local XUiSignWeekCard = XClass(XUiNode, "XUiSignWeekCard")
local XUiSignWeekRound = require("XUi/XUiSignIn/XUiSignWeekRound")

function XUiSignWeekCard:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.PanelSignPrefabs = {}
    self.SetTomorrowRound = -1
    self.PanelRounds = {}
    self.SignId = 0
    self.IsShow = false
end

function XUiSignWeekCard:Refresh(signId, isShow, purchasePackageData)
    self.SignId = signId
    self.IsShow = isShow
    self.IsPurchaseEnter = purchasePackageData ~= nil
    self.PurchaseData = purchasePackageData

    self.TempPanelRound = XUiHelper.TryGetComponent(self.Transform, "PanelRound", nil)

    if self.PanelSignPrefabs and next(self.PanelSignPrefabs) then
        for _, PanelSignPrefab in ipairs(self.PanelSignPrefabs) do
            PanelSignPrefab:Close()
        end
    else
        self.TempPanelRound.gameObject:SetActiveEx(false)
    end

    if self.IsPurchaseEnter then
        self:RefreshByPurchasePackageData()
    else
        self:RefreshByWeekCardData()
    end

    if self.RootUi and self.RootUi.RefreshBuyButtonStatus then
        self.RootUi:RefreshBuyButtonStatus(true)
    end
end

function XUiSignWeekCard:RefreshByPurchasePackageData()
    local signPrefab = self.PanelSignPrefabs[1]
    if not signPrefab then
        signPrefab = XUiSignWeekRound.New(self.TempPanelRound, self.RootUi, self)
    end
    self.PanelSignPrefabs[1] = signPrefab
    signPrefab:Refresh(self.SignId, 1, self.IsShow, self.PurchaseData)
    self:RefreshPanel(1)
end

function XUiSignWeekCard:RefreshByWeekCardData()
    local weekCardData = XDataCenter.PurchaseManager.GetWeekCardDataBySignInId(self.SignId)

    if not weekCardData then
        return
    end

    local roundsCount = weekCardData:GetRoundCount()

    for i = 1, roundsCount do
        local signPrefab = self.PanelSignPrefabs[i]
        if not signPrefab then
            local panelRound = nil
            if i == 1 then
                panelRound = self.TempPanelRound
            else
                panelRound = CS.UnityEngine.Object.Instantiate(self.TempPanelRound)
                panelRound.transform:SetParent(self.TempPanelRound.parent.transform, false)
            end
            signPrefab = XUiSignWeekRound.New(panelRound, self.RootUi, self, true, self.IsPurchaseEnter)
        end
        self.PanelSignPrefabs[i] = signPrefab
        
        signPrefab:Refresh(self.SignId, i, self.IsShow)
    end

    local curRound = weekCardData:GetCurRound()
    self:RefreshPanel(curRound)
end

function XUiSignWeekCard:RefreshPanel(round)
    for k, v in pairs(self.PanelSignPrefabs) do
        v:SetSignActive(k == round, round)
    end
end

function XUiSignWeekCard:OnHide()
end

function XUiSignWeekCard:OnShow()
end

return XUiSignWeekCard