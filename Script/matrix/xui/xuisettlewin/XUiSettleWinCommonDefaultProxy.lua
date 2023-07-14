local XUiSettleWinCommonDefaultProxy = XClass(nil, "XUiSettleWinCommonDefaultProxy")

function XUiSettleWinCommonDefaultProxy:Ctor(winData)
    
end

-- 获取子面板数据，主要用来增加编队界面自身玩法信息，就不用污染通用的预制体
--[[
    return : {
        assetPath : 资源路径
        proxy : 子面板代理
        proxyArgs : 子面板SetData传入的参数列表
    }
]]
function XUiSettleWinCommonDefaultProxy:GetChildPanelData()
    return nil
end

--######################## AOP ########################


function XUiSettleWinCommonDefaultProxy:AOPOnStartBefore(rootUi)
    
end

function XUiSettleWinCommonDefaultProxy:AOPOnStartAfter(rootUi)
    
end

return XUiSettleWinCommonDefaultProxy