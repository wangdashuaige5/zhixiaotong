package com.neusoft.make.po;

/**
 * @Description: 用户实体类
 *
 * @author: 高军
 *
 * @date: 2026-9-7
 */
public class User {
    private Integer id;
    private String account;
    private String password;
    private String real_name;
    private String role_code;
    private Integer dept_id;
    private String phone;
    private String email;
    private String harmony_device_id;
    private String face_feature;
    private Integer is_locked;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getAccount() {
        return account;
    }

    public void setAccount(String account) {
        this.account = account;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getReal_name() {
        return real_name;
    }

    public void setReal_name(String real_name) {
        this.real_name = real_name;
    }

    public String getRole_code() {
        return role_code;
    }

    public void setRole_code(String role_code) {
        this.role_code = role_code;
    }

    public Integer getDept_id() {
        return dept_id;
    }

    public void setDept_id(Integer dept_id) {
        this.dept_id = dept_id;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getHarmony_device_id() {
        return harmony_device_id;
    }

    public void setHarmony_device_id(String harmony_device_id) {
        this.harmony_device_id = harmony_device_id;
    }

    public String getFace_feature() {
        return face_feature;
    }

    public void setFace_feature(String face_feature) {
        this.face_feature = face_feature;
    }

    public Integer getIs_locked() {
        return is_locked;
    }

    public void setIs_locked(Integer is_locked) {
        this.is_locked = is_locked;
    }
}