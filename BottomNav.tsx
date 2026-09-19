'use client';
import Link from 'next/link';import {Home,Radio,Bookmark,Search,User} from 'lucide-react';import {usePathname} from 'next/navigation';
const items=[['/',Home,'Home'],['/live',Radio,'Live'],['/saved',Bookmark,'Saved'],['/search',Search,'Search'],['/profile',User,'Profile']] as const;
export default function BottomNav(){const path=usePathname();return <nav className="nav">{items.map(([href,Icon,label])=><Link key={href as string} href={href as string} className={path===href?'active':''}><Icon size={18}/><span>{label as string}</span></Link>)}</nav>}
