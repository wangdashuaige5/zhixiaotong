package com.neusoft.make.controller;

import java.util.Map;

import javax.servlet.http.HttpServletRequest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.neusoft.make.dto.PageDto;
import com.neusoft.make.service.IUserService;
import com.neusoft.util.Result;

/**
 * @Description: 用户管理专属Controller
 *
 * @author: 高军
 *
 * @date: 2026-9-7
 */
@CrossOrigin("*") // 允许跨域访问
@RestController
@RequestMapping("/user")
public class UserController {

    @Autowired
    IUserService userService;

    /**
     * [查询用户的方法(单表)]
     *
     * @param: keywords 用于查询的关键字
     * @param: pageNum 当前页码
     * @param: maxPageNum 每页显示的记录数量
     * @return: Result 数据传输对象
     */
    @RequestMapping("listUser")
    public Result listUser(String keywords, String pageNum, String maxPageNum, HttpServletRequest request) {
        System.out.println("keywords=" + keywords + " pageNum=" + pageNum + " maxPageNum=" + maxPageNum);
        PageDto pageDto = userService.listUser(keywords, Integer.parseInt(pageNum), Integer.parseInt(maxPageNum));
        return Result.success(pageDto);
    }

    /**
     * [查询用户的方法(多表)]
     *
     * @param: keywords 用于查询的关键字
     * @param: pageNum 当前页码
     * @param: maxPageNum 每页显示的记录数量
     * @return: Result 数据传输对象
     */
    @RequestMapping("listUser2")
    public Result listUser2(String keywords, String pageNum, String maxPageNum, HttpServletRequest request) {
        System.out.println("keywords=" + keywords + " pageNum=" + pageNum + " maxPageNum=" + maxPageNum);
        PageDto pageDto = userService.listUser2(keywords, Integer.parseInt(pageNum),
                Integer.parseInt(maxPageNum));
        return Result.success(pageDto);
    }

    /**
     * [添加用户的方法]
     *
     * @param: user 包含用户信息的Map集合
     * @return: 字符串 "1"==添加成功 "0"==添加失败
     */
    @RequestMapping(value = "addUser")
    public Result addUser(@RequestParam Map<String, Object> user, HttpServletRequest request) {
        int i = userService.addUser(user);
        if (i == 1) {
            return Result.success("1");
        }
        return Result.success("0");
    }

    /**
     * [更新用户信息的方法]
     *
     * @param: user 包含更新用户信息的Map集合
     * @return: 字符串 "1"==更新成功 "0"==更新失败
     */
    @RequestMapping("updateUser")
    public Result updateUser(@RequestParam Map<String, Object> user, HttpServletRequest request) {
        int i = userService.updateUserById(user);
        if (i == 1) {
            return Result.success("1");
        }
        return Result.success("0");
    }

    /**
     * [根据用户ID删除用户的方法 可以批量删除]
     *
     * @param: user_id 包含用户ID的字符串
     * @return: 字符串 "1"==删除成功 "0"==删除失败
     */
    @RequestMapping("deleteUser")
    public Result deleteUserById(@RequestParam String user_id, HttpServletRequest request) {
        int i = userService.deleteUserByIds(user_id);
        if (i == 1) {
            return Result.success("1");
        }
        return Result.success("0");
    }
}