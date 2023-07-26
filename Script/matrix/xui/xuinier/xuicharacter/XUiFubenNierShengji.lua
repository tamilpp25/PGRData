local XUiFubenNierShengji = XLuaUiManager.Register(XLuaUi, "UiFubenNierShengji")
local XGridNieRUpLvDetail = require("XUi/XUiNieR/XUiCharacter/XGridNieRUpLvDetail")
local XGridNieRPODUpLvDetail = require("XUi/XUiNieR/XUiCharacter/XGridNieRPODUpLvDetail")

function XUiFubenNierShengji:OnAwake()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    
    self.PanelShengjiDetail.gameObject:SetActiveEx(false)
    self.PanelPodShengjiDetail.gameObject:SetActiveEx(false)
end

function XUiFubenNierShengji:OnStart(dataList, podInfo, closeCb)
    self.CloseCb = closeCb
    self.DataList = dataList
    self.PodInfo = podInfo
end

function XUiFubenNierShengji:OnEnable()
    self:UpdateGrid(self.DataList, self.PodInfo)
end

function XUiFubenNierShengji:OnDisable()

end

function XUiFubenNierShengji:OnDestroy()

end

function XUiFubenNierShengji:UpdateGrid(dataList, podInfo)
    local upCharacterNum = #dataList
    local maxCharNum = podInfo and 2 or 3
    upCharacterNum = upCharacterNum > maxCharNum and maxCharNum or upCharacterNum
    for i = 1, upCharacterNum do
        local ui = CS.UnityEngine.Object.Instantiate(self.PanelShengjiDetail)
        local grid = XGridNieRUpLvDetail.New(self, ui)
        grid.Transform:SetParent(self.PanelShengjiList, false)
        grid.GameObject:SetActiveEx(true)
        grid:UpdateInfo(dataList[i])
    end

    if podInfo then
        local ui = CS.UnityEngine.Object.Instantiate(self.PanelPodShengjiDetail)
        local grid = XGridNieRPODUpLvDetail.New(self, ui)
        grid.Transform:SetParent(self.PanelShengjiList, false)
        grid.GameObject:SetActiveEx(true)
        grid:UpdateInfo(podInfo)
    end
end

function XUiFubenNierShengji:OnBtnCloseClick()
    if self.CloseCb then
        self.CloseCb()
    end
    self:Close()
end