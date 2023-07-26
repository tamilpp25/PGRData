--===========================
--超级爬塔主要页面子面板控制集成控件
--===========================
local XUiSTMainPage = XClass(nil, "XUiSTMainPage")

function XUiSTMainPage:Ctor(RootUi)
    self.RootUi = RootUi
end
--====================================
--根据子面板名<->序号字典，和脚本统一父路径注册所有子面板
--@param panelDic:枚举字典{Key = 子面板名， Value = 子面板序号} 
--@param scriptPath:所有子面板统一父路径
--所有子面板脚本取名都应为 父路径 + Key + "Panel"
--所有子面板GameObject/Transform都应在RootUi中使用"Panel" + Key的名字来索引
--====================================
function XUiSTMainPage:RegisterChildPanels(panelDic, scriptPath)
    if not self.ChildPanel then self.ChildPanel = {} end
    for key, index in pairs(panelDic) do
        local script = require(scriptPath .. key .. "Panel")
        if script and type(script) == "table" then
            self.ChildPanel[index] = script.New(self.RootUi["Panel" .. key], self.RootUi)
        end
    end
end
--========================
--根据显示面板序号字典来显隐所有子面板
--@param showIndexDic:{Key = 子面板序号， Value = true or nil/false面板显隐}
--序号字典中没有包含的子面板会被默认隐藏
--========================
function XUiSTMainPage:ShowChildPanel(showIndexDic)
    for index, panel in pairs(self.ChildPanel) do
        if showIndexDic[index]then
            panel:ShowPanel()
        else
            panel:HidePanel()
        end
    end
end
--========================
--显示所有面板
--========================
function XUiSTMainPage:ShowAllPanels()
    self:AllDoFunction("ShowPanel")
end
--========================
--根据子面板序号获取子面板
--========================
function XUiSTMainPage:GetChildPanelByIndex(index)
    return self.ChildPanel[index]
end
--========================
--根据子面板序号和方法名调用子面板控件方法
--@param index:子面板序号
--@param funcName:方法名
--@param ... :方法需要使用的所有参数
--========================
function XUiSTMainPage:DoFunction(index, funcName, ...)
    local panel = self.ChildPanel[index]
    if panel and panel[funcName] then
        return panel[funcName](panel, ...)
    end
end
--========================
--根据方法名调用所有子面板控件方法(通常用于模拟UI生命周期)
--@param funcName:方法名
--========================
function XUiSTMainPage:AllDoFunction(funcName)
    for _, panel in pairs(self.ChildPanel) do
        if panel[funcName] then
            panel[funcName](panel)
        end
    end
end

function XUiSTMainPage:OnEnable()
    self:AllDoFunction("OnEnable")
end

function XUiSTMainPage:OnDisable()
    self:AllDoFunction("OnDisable")
end

function XUiSTMainPage:OnDestroy()
    self:AllDoFunction("OnDestroy")
end

return XUiSTMainPage