local XUiPanelSignBoard = require("XUi/XUiMain/XUiChildView/XUiPanelSignBoard")

local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")
---@class XUiMainOther:XUiMainPanelBase
local XUiMainOther = XClass(XUiMainPanelBase, "XUiMainOther")

function XUiMainOther:OnStart(rootUi)
    -- self.Transform = rootUi.PanelOther.gameObject.transform
    -- XTool.InitUiObject(self)
    self.RootUi = rootUi
    --self.SignBoard = XUiPanelSignBoard.New(self.PanelSignBoard, self.RootUi, XUiPanelSignBoard.SignBoardOpenType.MAIN)
    
    --RedPoint

    XEventManager.AddEventListener(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN, self.OnChangeSync, self)
end

function XUiMainOther:OnEnable()
    if self.SignBoard then
        -- 随机角色
        local displayCharacterId = XDataCenter.DisplayManager.GetRandomDisplayCharByList().Id

        -- 刷新
        XDataCenter.DisplayManager.SetNextDisplayChar(nil)
        self.SignBoard:SetDisplayCharacterId(displayCharacterId)
        self.SignBoard:OnEnable()
    end
end

function XUiMainOther:OnDisable()
    if self.SignBoard then
        self.SignBoard:OnDisable()
    end
end

function XUiMainOther:OnDestroy()
    if self.SignBoard then
        self.SignBoard:OnDestroy()
    end
    self.SignBoard = nil

    XEventManager.RemoveEventListener(XEventId.EVENT_PHOTO_SYNC_CHANGE_TO_MAIN, self.OnChangeSync, self)
end

function XUiMainOther:Stop()
    if not self.SignBoard then
        return
    end
    self.SignBoard:Stop()
end

function XUiMainOther:SetSignBoardEnable(enable)
    if not self.SignBoard then
        return
    end
    self.SignBoard:SetEnable(enable)
end

function XUiMainOther:SafeCreateSignBoard()
    if self.SignBoard then
        return
    end
    ---@type XUiPanelSignBoard
    self.SignBoard = XUiPanelSignBoard.New(self.PanelSignBoard, self.RootUi, XUiPanelSignBoard.SignBoardOpenType.MAIN)
    self:OnEnable()
end

function XUiMainOther:OnChangeSync()
    if self.SignBoard then
        self.SignBoard:OnDestroy()
    end
    self.SignBoard = nil
end

return XUiMainOther