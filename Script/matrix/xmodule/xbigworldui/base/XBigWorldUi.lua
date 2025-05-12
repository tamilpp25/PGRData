---@class XBigWorldUi : XLuaUi 大世界UI专用
---@field _IsPauseFight boolean 界面打开时是否暂停战斗
---@field _IsChangeInput boolean 界面打开时是否切换为系统输入
---@field _IsCloseLittleMap boolean 界面打开时是否关闭小地图
local XBigWorldUi = XClass(XLuaUi, "XBigWorldUi")

function XBigWorldUi:OnAwakeUi()
    self._IsPauseFight = XMVCA.XBigWorldUI:IsPauseFight(self.Name)
    self._IsChangeInput = XMVCA.XBigWorldUI:IsChangeInput(self.Name)
    self._IsCloseLittleMap = XMVCA.XBigWorldUI:IsCloseLittleMap(self.Name)
    self._IsHideFightUi = XMVCA.XBigWorldUI:IsHideFightUi(self.Name)
    if self._IsPauseFight then
        XMVCA.XBigWorldGamePlay:PauseFight()
    end

    if self._IsChangeInput then
        XMVCA.XBigWorldUI:AddInputRefCount()
    end

    if self._IsCloseLittleMap then
        XMVCA.XBigWorldMap:CloseBigWorldLittleMapUi()
    end

    if self._IsHideFightUi then
        XMVCA.XBigWorldGamePlay:SetFightUiActive(false)
    end

    XMVCA.XBigWorldUI:HideOtherUi(self.Name)

    XLuaUi.OnAwakeUi(self)
end

function XBigWorldUi:OnDestroyUi()
    if self._IsPauseFight then
        XMVCA.XBigWorldGamePlay:ResumeFight()
    end

    if self._IsChangeInput then
        XMVCA.XBigWorldUI:SubInputRefCount()
    end

    if self._IsCloseLittleMap then
        XMVCA.XBigWorldMap:OpenBigWorldLittleMapUi()
    end

    if self._IsHideFightUi then
        XMVCA.XBigWorldGamePlay:SetFightUiActive(true)
    end

    XMVCA.XBigWorldUI:ShowOtherUi(self.Name)

    XLuaUi.OnDestroyUi(self)
end

function XBigWorldUi:ChangePauseFight(value)
    if value ~= self._IsPauseFight then
        if self._IsPauseFight then
            XMVCA.XBigWorldGamePlay:ResumeFight()
        else
            XMVCA.XBigWorldGamePlay:PauseFight()
        end
        self._IsPauseFight = value
    end
end

function XBigWorldUi:ChangeInput(value)
    if value ~= self._IsChangeInput then
        if self._IsChangeInput then
            XMVCA.XBigWorldUI:SubInputRefCount()
        else
            XMVCA.XBigWorldUI:AddInputRefCount()
        end
        self._IsChangeInput = value
    end
end

function XBigWorldUi:ChangeCloseLittleMap(value)
    if value ~= self._IsCloseLittleMap then
        if self._IsCloseLittleMap then
            XMVCA.XBigWorldMap:OpenBigWorldLittleMapUi()
        else
            XMVCA.XBigWorldMap:CloseBigWorldLittleMapUi()
        end
        self._IsCloseLittleMap = value
    end
end

function XBigWorldUi:ChangeHideFightUi(value)
    if value ~= self._IsHideFightUi then
        if self._IsHideFightUi then
            XMVCA.XBigWorldGamePlay:SetFightUiActive(true)
        else
            XMVCA.XBigWorldGamePlay:SetFightUiActive(false)
        end
        self._IsHideFightUi = value
    end
end

return XBigWorldUi
