-- 新回归活动的子活动接口，全部子活动必须实现该接口内部方法
local XINewRegressionChildManager = XClass(nil, "XINewRegressionChildManager")

-- 入口按钮排序权重，越小越前，可以重写自己的权重
function XINewRegressionChildManager:GetButtonWeight()
    return 0
end

-- 入口按钮显示名称
function XINewRegressionChildManager:GetButtonName()
    return "unknow"
end

-- 获取面板控制数据
function XINewRegressionChildManager:GetPanelContrlData()
    return {
        assetPath = "资源路径",
        proxy = "面板控制代理(必须实现SetData方法)",
        proxyArgs = {"SetData代理参数1"}
    }
end

-- 用来显示页签和统一入口的小红点
function XINewRegressionChildManager:GetIsShowRedPoint(...)
    return false
end

-- 获取该子活动管理器是否开启
function XINewRegressionChildManager:GetIsOpen()
    return true
end

return XINewRegressionChildManager