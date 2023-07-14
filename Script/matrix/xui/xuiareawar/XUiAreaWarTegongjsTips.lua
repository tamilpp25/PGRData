local XUiGridAreaWarSpecialRole = require("XUi/XUiAreaWar/XUiGridAreaWarSpecialRole")

--特攻角色解锁弹窗
local XUiAreaWarTegongjsTips = XLuaUiManager.Register(XLuaUi, "UiAreaWarTegongjsTips")

function XUiAreaWarTegongjsTips:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)

    self.Container = self.Transform:FindTransform("Container")
    self.GridRole.gameObject:SetActiveEx(false)
end

function XUiAreaWarTegongjsTips:OnStart(closeCb)
    self.CloseCb = closeCb
    self.GridList = {}

    self:Refresh()
end

function XUiAreaWarTegongjsTips:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiAreaWarTegongjsTips:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE
    }
end

function XUiAreaWarTegongjsTips:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE then
        self:Refresh()
    end
end

function XUiAreaWarTegongjsTips:Refresh()
    local oldCount, newCount = XDataCenter.AreaWarManager.GetRecordUnlockSpecialRoleCount()
    self.TxtOld.text = oldCount
    self.TxtNew.text = newCount

    local roleIds = XDataCenter.AreaWarManager.GetRecordSpecialRoleIds()
    for index, roleId in ipairs(roleIds) do
        local grid = self.GridList[index]
        if not grid then
            local go = CSObjectInstantiate(self.GridRole, self.Container)
            grid = XUiGridAreaWarSpecialRole.New(go)
            self.GridList[index] = grid
        end

        grid:Refresh(roleId)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #roleIds + 1, #self.GridList do
        self.GridList[index].GameObject:SetActiveEx(false)
    end
end
