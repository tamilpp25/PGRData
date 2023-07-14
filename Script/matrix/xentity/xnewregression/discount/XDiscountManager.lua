local XINewRegressionChildManager = require("XEntity/XNewRegression/XINewRegressionChildManager")

local CheckIsClickDiscountKey = "CheckIsClickDiscount"

--回归礼包购买
local XDiscountManager = XClass(XINewRegressionChildManager, "XDiscountManager")

function XDiscountManager:SaveClickCookie()
    if not self:GetIsShowRedPoint() then
        return
    end
    XSaveTool.SaveData(XDataCenter.NewRegressionManager.GetLocalSaveKey() .. CheckIsClickDiscountKey, true)
end

function XDiscountManager:IsDiscount()
    return true
end

--######################## XINewRegressionChildManager接口 ########################

-- 入口按钮排序权重，越小越前，可以重写自己的权重
function XDiscountManager:GetButtonWeight()
    return tonumber(XNewRegressionConfigs.GetChildActivityConfig("DiscountButtonWeight"))
end

-- 入口按钮显示名称
function XDiscountManager:GetButtonName()
    return XNewRegressionConfigs.GetChildActivityConfig("DiscountButtonName")
end

-- 获取面板控制数据
function XDiscountManager:GetPanelContrlData()
    return {
        assetPath = XNewRegressionConfigs.GetChildActivityConfig("DiscountPrefabAssetPath"),
        proxy = require("XUi/XUiNewRegression/Discount/XUiPanelDiscount"),
    }
end

-- 获取该子活动管理器是否开启
function XDiscountManager:GetIsOpen()
    return XDataCenter.NewRegressionManager.GetIsOpenByActivityState(XNewRegressionConfigs.ActivityState.InRegression)
end

-- 用来显示页签和统一入口的小红点
-- 检查是否点击过了页签
function XDiscountManager:GetIsShowRedPoint(...)
    return not XSaveTool.GetData(XDataCenter.NewRegressionManager.GetLocalSaveKey() .. CheckIsClickDiscountKey)
end

return XDiscountManager