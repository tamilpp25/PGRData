---@class XMovieControl : XControl
---@field _Model XMovieModel
local XMovieControl = XClass(XControl, "XMovieControl")
function XMovieControl:OnInit()
    --初始化内部变量
end

function XMovieControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XMovieControl:RemoveAgencyEvent()

end

function XMovieControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

--============================================================== #region 配置表 ==============================================================
--- 获取名词注释配置
function XMovieControl:GetKeywordConfig(id)
    return self._Model:GetKeywordConfig(id)
end
--============================================================== #endregion 配置表 ==============================================================

return XMovieControl