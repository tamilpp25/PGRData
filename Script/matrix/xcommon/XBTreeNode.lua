-- 定义二叉树节点
---@class XBTreeNode
XBTreeNode = XClass(nil, "XBTreeNode")
function XBTreeNode:Ctor(data, depth, parent)
    self.Data = data
    self.ExtraData = nil
    self.Parent = parent
    self.Left = nil
    self.Right = nil
    self.Depth = depth -- 记录节点深度
end