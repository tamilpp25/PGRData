
---@class XUiSkyGardenCafePopupCardDetail : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyGardenCafeControl
local XUiSkyGardenCafePopupCardDetail = XLuaUiManager.Register(XLuaUi, "UiSkyGardenCafePopupCardDetail")

function XUiSkyGardenCafePopupCardDetail:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafePopupCardDetail:OnStart(cardId)
    self._CardId = cardId
    self:InitView()
end

function XUiSkyGardenCafePopupCardDetail:InitUi()
    self._PanelCard = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGCardItem").New(self.UiSkyGardenCafeCard, self)
end

function XUiSkyGardenCafePopupCardDetail:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
end

function XUiSkyGardenCafePopupCardDetail:InitView()
    self._PanelCard:RefreshDetail(self._CardId)
end