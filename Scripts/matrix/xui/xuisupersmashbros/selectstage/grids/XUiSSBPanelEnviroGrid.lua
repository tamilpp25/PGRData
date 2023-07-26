--===========================
--选择关卡环境列表项控件
--===========================
local XUiSSBPanelEnviroGrid = XClass(nil, "XUiSSBPanelEnviroGrid")

local TextName = {
        Name = 0, --名称文本
        Desc = 1, --描述文本
        Gain = 2, --增益文本
    }

function XUiSSBPanelEnviroGrid:Ctor(grid, environCfg, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, grid)
    self:Refresh(environCfg)
end
--==============
--刷新
--==============
function XUiSSBPanelEnviroGrid:Refresh(environCfg)
    self.EnvironCfg = environCfg
    self.BtnEnvironment:SetNameByGroup(TextName.Name, self.EnvironCfg.Name)
    self.BtnEnvironment:SetNameByGroup(TextName.Desc, self.EnvironCfg.Description)
    self.BtnEnvironment:SetNameByGroup(TextName.Gain, XUiHelper.GetText("SSBGainText", self.EnvironCfg.PowerPercent))
end
--==============
--获取UiButton组件
--==============
function XUiSSBPanelEnviroGrid:GetButton()
    return self.BtnEnvironment
end
--==============
--获取Environ配置
--==============
function XUiSSBPanelEnviroGrid:GetEnvironment()
    return self.EnvironCfg
end
--==============
--点击时
--==============
function XUiSSBPanelEnviroGrid:OnSelect(value)
    --if value then self.RootUi:SetSelectEnvironment(self.EnvironCfg) end
end
return XUiSSBPanelEnviroGrid