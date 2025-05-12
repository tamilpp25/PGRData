local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTemple2PopupChapterDetailGrid = require("XUi/XUiTemple2/System/Main/XUiTemple2PopupChapterDetailGrid")
local XUiTemple2PopupChapterDetailGridBlock = require("XUi/XUiTemple2/System/Main/XUiTemple2PopupChapterDetailGridBlock")

---@class XUiTemple2PopupChapterDetail : XLuaUi
---@field _Control XTemple2Control
local XUiTemple2PopupChapterDetail = XLuaUiManager.Register(XLuaUi, "UiTemple2PopupChapterDetail")

function XUiTemple2PopupChapterDetail:Ctor()
    self._Grids = {}
end

function XUiTemple2PopupChapterDetail:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnScore, self.OnClickRecord)
    self:RegisterClickEvent(self.BtnStart, self.OnClickStart)
    self.BtnHead.gameObject:SetActiveEx(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelGoodsList)
    self.DynamicTable:SetProxy(XUiTemple2PopupChapterDetailGridBlock, self)
    self.DynamicTable:SetDelegate(self)
    self.GridGoods.gameObject:SetActiveEx(false)
end

function XUiTemple2PopupChapterDetail:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE2_UPDATE_NPC_LIST, self.Update, self)
end

function XUiTemple2PopupChapterDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE2_UPDATE_NPC_LIST, self.Update, self)
end

function XUiTemple2PopupChapterDetail:Update()
    self._Control:GetSystemControl():UpdateStageDetail()
    local stageDetail = self._Control:GetSystemControl():GetDataStageDetail()
    self.TxtTiTle.text = stageDetail.Name
    self.TxtDetail.text = stageDetail.Desc
    if stageDetail.SelectedCharacter then
        self.RImgCharater:SetRawImage(stageDetail.SelectedCharacter.Icon)
        self.TxtChat.text = stageDetail.SelectedCharacter.Desc
    end
    self.TxtNum.text = stageDetail.HistoryScore
    local characterList = stageDetail.CharacterList
    XTool.UpdateDynamicItem(self._Grids, characterList, self.BtnHead, XUiTemple2PopupChapterDetailGrid, self)
    
    -- 需要根据喜好, 过滤地块
    self:UpdateBlockDesc()
end

function XUiTemple2PopupChapterDetail:OnClickRecord()
    self._Control:GetSystemControl():PlayHistory()
end

function XUiTemple2PopupChapterDetail:OnClickStart()
    self._Control:GetSystemControl():StartGame()
end

function XUiTemple2PopupChapterDetail:UpdateBlockDesc()
    self:PlayAnimation("QieHuan")
    local dataSource = self._Control:GetSystemControl():GetDataStageDetailOfBlock()
    self.DynamicTable:SetDataSource(dataSource)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiTemple2PopupChapterDetailGridBlock
function XUiTemple2PopupChapterDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    end
end

return XUiTemple2PopupChapterDetail