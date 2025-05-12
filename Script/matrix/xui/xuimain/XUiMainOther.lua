local XUiPanelSignBoard = require("XUi/XUiMain/XUiChildView/XUiPanelSignBoard")

local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")
---@class XUiMainOther:XUiMainPanelBase
local XUiMainOther = XClass(XUiMainPanelBase, "XUiMainOther")

local HasSceneChanged = false -- 刚刚触发了场景切换

function XUiMainOther:OnStart(rootUi)
    -- self.Transform = rootUi.PanelOther.gameObject.transform
    -- XTool.InitUiObject(self)
    self.RootUi = rootUi
    XEventManager.AddEventListener(XEventId.EVENT_PHOTO_SYNC_CHANGE_BACKGROUND, self.OnBackgrondChanged, self)
    --self.SignBoard = XUiPanelSignBoard.New(self.PanelSignBoard, self.RootUi, XUiPanelSignBoard.SignBoardOpenType.MAIN)
    
    --RedPoint
end

function XUiMainOther:OnBackgrondChanged()
    HasSceneChanged = true
end

function XUiMainOther:OnEnable()
    -- 触发场景切换 则下一次随机请求取消
    if HasSceneChanged then
        HasSceneChanged = false
        return
    end

    if self.SignBoard then
        -- 随机角色
        self.SignBoard:DoRandomAndChangeDisplayCharacter(true)
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

    XEventManager.RemoveEventListener(XEventId.EVENT_PHOTO_SYNC_CHANGE_BACKGROUND, self.OnBackgrondChanged, self)
end

function XUiMainOther:Stop()
    if not self.SignBoard then
        return
    end
    self.SignBoard:Stop()
end

function XUiMainOther:ForceStop()
    if not self.SignBoard then
        return
    end
    self.SignBoard:Stop(true)
end

function XUiMainOther:SetSignBoardEnable(enable)
    if not self.SignBoard then
        return
    end
    self.SignBoard:SetEnable(enable)
end

function XUiMainOther:SafeCreateSignBoard()
    if self.SignBoard then
        if self.SignBoard:IsPrepareDestory() then
            self.SignBoard:OnDestroy()
            self.SignBoard = nil
        else
            return
        end
    end
    ---@type XUiPanelSignBoard
    self.SignBoard = XUiPanelSignBoard.New(self.PanelSignBoard, self.RootUi, XUiPanelSignBoard.SignBoardOpenType.MAIN)
    self:OnEnable()
end

function XUiMainOther:OnChangeSync()
    if self.SignBoard then
        if self.SignBoard.Enable then
            self.SignBoard:OnDestroy()
            self.SignBoard = nil
        else
            -- 如果现在在拍照界面 直接销毁self.SignBoard会把PlayingElement也销毁 从而影响拍照界面的逻辑 所以这里做了延后处理
            self.SignBoard:SetPrepareDestory()
        end
    end
end

function XUiMainOther:GetRoleModel()
    if self.SignBoard then
        return self.SignBoard.RoleModel
    end
    return false
end

function XUiMainOther:ForceStopAnim()
    self.SignBoard:OnStop(self.SignBoard.SignBoardPlayer.PlayerData.PlayingElement, true)
end

---@return UnityEngine.Transform
function XUiMainOther:GetRoleModelTransform()
    if self.SignBoard and self.SignBoard.DisplayState and not XTool.UObjIsNil(self.SignBoard.DisplayState.Model) then
        return self.SignBoard.DisplayState.Model.transform
    end
    return nil
end

return XUiMainOther
