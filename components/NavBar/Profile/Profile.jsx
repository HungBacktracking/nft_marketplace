import React from "react";
import Image from "next/image";
import { FaUserAlt, FaRegImage, FaUserEdit, FaCog, FaLanguage, FaAddressBook, FaUsers } from "react-icons/fa";
import { MdHelpCenter } from "react-icons/md";
import { TbDownloadOff, TbDownload } from "react-icons/tb";
import Link from "next/link";

//INTERNAL IMPORT
import Style from "./Profile.module.css";
import images from "../../../img";

const Profile = () => {
  return (
    <div className={Style.profile}>
      <div className={Style.profile_account}>
        <Image
          src={images.user1}
          alt="user profile"
          width={50}
          height={50}
          className={Style.profile_account_img}
        />

        <div className={Style.profile_account_info}>
          <p>Shoaib Bhai</p>
          <small>X038499382920203...</small>
        </div>
      </div>

      <div className={Style.profile_menu}>
        <div className={Style.profile_menu_one}>
          <div className={Style.profile_menu_one_item}>
            <FaUserAlt />
            <p>
              <Link href={{ pathname: "/author" }}>My Profile</Link>
            </p>
          </div>

          <div className={Style.profile_menu_one_item}>
            <FaCog />
            <p>
              <Link href={{ pathname: "/setting" }}>Setting</Link>
            </p>
          </div>

          <div className={Style.profile_menu_one_item}>
            <FaLanguage />
            <p>
              <Link href={{ pathname: "/language" }}>Language</Link>
            </p>
          </div>

          <div className={Style.profile_menu_one_item}>
            <FaAddressBook />
            <p>
              <Link href={{ pathname: "/privacy" }}>Privacy</Link>
            </p>
          </div>

          <div className={Style.profile_menu_one_item}>
            <FaUsers />
            <p>
              <Link href={{ pathname: "/community" }}>Community</Link>
            </p>
          </div>

          <div className={Style.profile_menu_one_item}>
            <FaUserEdit />
            <p>
              <Link href={{ pathname: "/account" }}>Edit Profile</Link>
            </p>
          </div>
        </div>

        
          <div className={Style.profile_menu_one_item}>
            <TbDownload />
            <p>
              <Link href={{ pathname: "/disconnet" }}>Disconnet</Link>
            </p>
          </div>
        </div>
      </div>
  );
};

export default Profile;
