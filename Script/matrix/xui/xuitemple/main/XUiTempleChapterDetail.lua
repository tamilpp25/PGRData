local XUiTempleBattleGrid = require("XUi/XUiTemple/XUiTempleBattleGrid")
local XUiTempleSettlementStar = require("XUi/XUiTemple/Main/XUiTempleSettlementStar")
local XUiTempleChapterDetailRuleGrid = require("XUi/XUiTemple/Main/XUiTempleChapterDetailRuleGrid")
local XUiTempleChangeRole = require("XUi/XUiTemple/Main/XUiTempleChangeRole")
local XUiTempleUtil = require("XUi/XUiTemple/XUiTempleUtil")
local XUiTempleChessBoardPanel = require("XUi/XUiTemple/XUiTempleChessBoardPanel")

---@field _Control XTempleControl
---@class XUiTempleChapterDetail:XLuaUi
local XUiTempleChapterDetail = XLuaUiManager.Register(XLuaUi, "UiTempleChapterDetail")

function XUiTempleChapterDetail:Ctor()
    ---@type XTempleUiControl
    self._UiControl = self._Control:GetUiControl()

    ---@type XTempleGameControl
    self._GameControl = self._Control:GetGameControl()

    self._Grids = {}

    self._Rules = {}
end

function XUiTempleChapterDetail:OnAwake()
    self:BindExitBtns(self.BtnTanchuangClose)
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnStart, self._OnClickStart)
    self:RegisterClickEvent(self.BtnChange, self._OnClickChangeRole)
    self:RegisterClickEvent(self.BtnExchangeEmpty, self._OnClickCloseChangeRole)
    ---@type XUiTempleChangeRole
    --self._PanelChangeRole = XUiTempleChangeRole.New(self.PaneExchange, self)
    self.Checkerboard.gameObject:SetActiveEx(true)

    self.GridStar1.gameObject:SetActiveEx(false)
    self.GridStar2.gameObject:SetActiveEx(false)
    self.GridStar3.gameObject:SetActiveEx(false)
    self._Star1 = XUiTempleSettlementStar.New(self.GridStar1, self)
    self._Star2 = XUiTempleSettlementStar.New(self.GridStar2, self)
    self._Star3 = XUiTempleSettlementStar.New(self.GridStar3, self)

    ---@type XUiTempleChessBoardPanel
    self._PanelChessBoard = XUiTempleChessBoardPanel.New(self.ImgCapture2 or self.ImgCapture, self)

    self.ImgValentinesDayTarget = self.ImgValentinesDayTarget or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelLeft/PanelTarget/ImgValentinesDayTarget", "Transform")
end

function XUiTempleChapterDetail:OnStart(stageId)
    self._UiControl:SetCurrentStageId(stageId)
    self._GameControl:StartGame(stageId)
    XMVCA.XTemple:SetStageNotJustUnlock(stageId)
end

function XUiTempleChapterDetail:OnEnable()
    self:Update()
    self:_UpdateCharacter()
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_UPDATE_CHANGE_ROLE, self._UpdateCharacter, self)
end

function XUiTempleChapterDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_UPDATE_CHANGE_ROLE, self._UpdateCharacter, self)
end

function XUiTempleChapterDetail:Update()
    local detailBg = self._GameControl:GetStageDetailBg()
    self.TxtNum.text = self._GameControl:GetStageBestScore()
    self.TxtTitle.text = self._GameControl:GetStageName()
    self.ImgCapture:SetRawImage(detailBg)

    local dataProvider = self._GameControl:GetGrids()
    local bg = self._GameControl:GetStageBg()
    self._PanelChessBoard:Update(dataProvider, bg, false)

    if self._GameControl:IsCoupleChapter() then
        self.PanelStar.gameObject:SetActiveEx(false)
        --self.PanelBestScore.gameObject:SetActiveEx(false)
        self.BtnChange.gameObject:SetActiveEx(true)
        self.ImgValentinesDayTarget.gameObject:SetActiveEx(true)
        --self.PanelAffix.gameObject:SetActiveEx(false)
    else
        self.PanelStar.gameObject:SetActiveEx(true)
        self.PanelBestScore.gameObject:SetActiveEx(true)
        self.BtnChange.gameObject:SetActiveEx(false)
        self.ImgValentinesDayTarget.gameObject:SetActiveEx(false)
        --self.PanelAffix.gameObject:SetActiveEx(true)
        local star = self._GameControl:GetDataStar()
        self._Star1:Update(star[1])
        self._Star2:Update(star[2])
        self._Star3:Update(star[3])
    end

    local rules = self._GameControl:GetRule(true)
    self:UpdateDynamicItem(self._Rules, rules, self.GridAffix, XUiTempleChapterDetailRuleGrid)
end

function XUiTempleChapterDetail:UpdateDynamicItem(gridArray, dataArray, uiObject, class)
    XUiTempleUtil:UpdateDynamicItem(self, gridArray, dataArray, uiObject, class)
end

function XUiTempleChapterDetail:_OnClickStart()
    self._Control:StartGame(function()
        XLuaUiManager.SafeClose(self.Name)
    end)
end

function XUiTempleChapterDetail:_OnClickChangeRole()
    --self._PanelChangeRole:Open()
    XLuaUiManager.Open("UiTempleExchange")
end

function XUiTempleChapterDetail:_OnClickCloseChangeRole()
    --self._PanelChangeRole:Close()
end

function XUiTempleChapterDetail:_UpdateCharacter()
    local body
    if self._GameControl:IsCoupleChapter() then
        body = self._UiControl:GetSelectedCharacterIcon()
    else
        local text
        text, body = self._UiControl:GetStageCharacterTextAndImage()
    end
    self.RImgCharater:SetRawImage(body)
    if self.RImgShadow then
        self.RImgShadow:SetRawImage(body)
    end
    self.TxtChat.text = self._GameControl:GetStageEnterText()
end

function XUiTempleChapterDetail:UpdateBg()
    --ImgCapture
end

return XUiTempleChapterDetail
