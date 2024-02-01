local XUiTempleBattleGrid = require("XUi/XUiTemple/XUiTempleBattleGrid")
local XUiTempleSettlementStar = require("XUi/XUiTemple/Main/XUiTempleSettlementStar")

---@class XUiTempleSettlement : XLuaUi
---@field _Control XTempleControl
local XUiTempleSettlement = XLuaUiManager.Register(XLuaUi, "UiTempleSettlement")

function XUiTempleSettlement:OnAwake()
    self._GameControl = self._Control:GetGameControl()
    self:AddBtnListener()

    self._Grids = {}

    self._Star1 = XUiTempleSettlementStar.New(self.GridStar1, self)
    self._Star2 = XUiTempleSettlementStar.New(self.GridStar2, self)
    self._Star3 = XUiTempleSettlementStar.New(self.GridStar3, self)
end

function XUiTempleSettlement:OnStart()

end

function XUiTempleSettlement:OnEnable()
    self:Update()
    self._GameControl:ClearGame()
end

function XUiTempleSettlement:OnDisable()

end

function XUiTempleSettlement:OnDestroy()

end

function XUiTempleSettlement:AddBtnListener()
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnRestart, self.OnClickRestart)
    self:RegisterClickEvent(self.BtnExit, self.Close)
end

function XUiTempleSettlement:Update()
    local dataProvider = self._GameControl:GetGrids()
    self:UpdateDynamicItem(self._Grids, dataProvider, self.GridCheckerboard, XUiTempleBattleGrid)
    self.TxtNum.text = self._GameControl:GetCurrentScore4Settle()
    self.TxtTitle.text = self._GameControl:GetStageName()

    if self._GameControl:IsCoupleChapter() then
        self.PanelTarget.gameObject:SetActiveEx(false)
    else
        if self._GameControl:IsChallengeSuccess() then
            self.TxtSettlement.gameObject:SetActiveEx(true)
        else
            self.TxtSettlement.gameObject:SetActiveEx(false)
        end
        local star = self._GameControl:GetDataSettleStar()
        self._Star1:Update(star[1])
        self._Star2:Update(star[2])
        self._Star3:Update(star[3])
    end

    local text, body = self._GameControl:GetTextSettlement()
    self.TxtChat.text = text
    self.RImgCharacter:SetRawImage(body)

    local imgCapture = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/ImgCapture", "RawImage")
    imgCapture:SetRawImage(self._GameControl:GetStageBg())

    if self._GameControl:IsChallengeSuccess() then
        local ui = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelTitle/TxtSettlement", "Transform")
        ui.gameObject:SetActiveEx(true)
    else
        local ui = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelTitle/TxtSettlementFail", "Transform")
        ui.gameObject:SetActiveEx(true)
    end
    self._GameControl:PlayMusicSettle()
end

function XUiTempleSettlement:UpdateDynamicItem(gridArray, dataArray, uiObject, class)
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, #dataArray do
        local grid = gridArray[i]
        if not grid then
            local uiObject = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = class.New(uiObject, self)
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = #dataArray + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

function XUiTempleSettlement:OnClickRestart()
    self._GameControl:RestartAfterSettle(function()
        XLuaUiManager.SafeClose(self.Name)
    end)
end

return XUiTempleSettlement
