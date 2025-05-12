local Default = {
    _Id = 0,
    _CfgId = 0, --配置Id
    _ProgressDay = 0, --已建造天数/工作天数
    _IsDone = false, --是否建造完成
    _BuildingIndex = 0, --建筑Index
    _WorkingInhabitantCount = 0, --工作中占用居民数量
    _State = XDoomsdayConfigs.BUILDING_STATE.EMPTY, --建筑状态
    _RecoveryDay = 0, --第几天恢复开工
}

--末日生存玩法-建筑
local XDoomsdayBuilding = XClass(XDataEntityBase, "XDoomsdayBuilding")

function XDoomsdayBuilding:Ctor()
    self:Init(Default)
end

function XDoomsdayBuilding:UpdateData(data)
    self:SetProperty("_Id", data.Id)
    self:SetProperty("_CfgId", data.CfgId)
    self:SetProperty("_ProgressDay", data.Progress)
    self:SetProperty("_IsDone", data.IsFinish)
    self:SetProperty("_BuildingIndex", data.Pos + 1)
    self:SetProperty("_RecoveryDay", data.RecoveryDay)
end

function XDoomsdayBuilding:IsEmpty()
    return not XTool.IsNumberValid(self._CfgId)
end

return XDoomsdayBuilding
