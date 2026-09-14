package com.neusoft.make.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.neusoft.make.po.User;

/**
 * @Description: 用户Mapper接口
 *
 * @author: 高军
 *
 * @date: 2026-9-7
 */
@Mapper
public interface UserMapper {

    /**
     * @Description: 单条件获取用户数量(单表)
     * @param: keywords 查询条件关键字
     * @return: 整数
     * @exception: 无
     */
    public int getUserCount(@Param("keywords") String keywords);

    /**
     * @Description: 单条件分页获取用户记录(单表)
     * @param: keywords 查询条件关键字
     * @param: pageNum 起始页数
     * @param: maxPageNum 每页最多显示的记录数
     * @return: 用户对象集合
     * @exception: 无
     */
    public List<User> listUser(@Param("keywords") String keywords, @Param("pageNum") int pageNum,
            @Param("maxPageNum") int maxPageNum);

    /**
     * @Description: 用户添加
     * @param: user 包含用户信息的Map对象
     * @return: 整数1 为成功
     * @exception: 无
     */
    public int addUser(Map<String, Object> user);

    /**
     * @Description: 用户更新
     * @param: user 包含用户信息的Map对象
     * @return: 整数1 为成功
     * @exception: 无
     */
    public int updateUserById(Map<String, Object> user);

    /**
     * @Description: 用户删除
     * @param: user_id 包含用户编号信息的字符串对象
     * @return: 整数1 为成功
     * @exception: 无
     */
    public int deleteUserByIds(String user_id);

    // 以下为多表操作
    /**
     * @Description: 单条件获取用户数量(多表)
     * @param: keywords 查询条件关键字
     * @return: 整数
     * @exception: 无
     */
    public int getUserCount2(@Param("keywords") String keywords);

    /**
     * @Description: 单条件分页获取用户记录(多表)
     * @param: keywords 查询条件关键字
     * @param: pageNum 起始页数
     * @param: maxPageNum 每页最多显示的记录数
     * @return: 用户对象集合
     * @exception: 无
     */
    public List<Map<String, Object>> listUser2(@Param("keywords") String keywords, @Param("pageNum") int pageNum,
            @Param("maxPageNum") int maxPageNum);

}