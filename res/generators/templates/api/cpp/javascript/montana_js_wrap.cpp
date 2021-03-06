#include "..\I<%= $cur_module.name %>.h"
#include "api_generator\js_helpers.h"

#include "logging/RhoLog.h"
#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "<%= $cur_module.name %>"

#include "common/StringConverter.h"

extern "C" void rho_wm_impl_performOnUiThread(rho::common::IRhoRunnable* pTask);

using namespace rho;
using namespace rho::json;
using namespace rho::common;

<% $cur_module.methods.each do |module_method| %>
<%= api_generator_MakeJSMethodDecl($cur_module.name, module_method)%>
{
    CMethodResult oRes;

    rho::common::IRhoRunnable* pFunctor = 0;
    bool bUseCallback = false;
    int argc = argv.getSize();
    int nCallbackArg = 0;
<% if module_method.access != ModuleMethod::ACCESS_STATIC %>
    I<%= $cur_module.name %>* pObj = C<%= $cur_module.name %>FactoryBase::getInstance()->getModuleByID(convertToStringW(strObjID));
<%end%>

<% functor_params = ""; first_arg = 0; 
   module_method.params.each do |param| %>
    nCallbackArg = <%= first_arg + 1 %>;

    <% if !param.can_be_nil %>
    if ( argc == <%= first_arg %> )
    {
        oRes.setArgError(L"Wrong number of arguments: " + convertToStringW(argc) + L" instead of " + convertToStringW(<%= module_method.params.size() %>) );
        return oRes.toJSON();
    }
    <% end %>

<% if param.type == MethodParam::TYPE_STRING %>
    <%= api_generator_cpp_makeNativeType(param.type) %> arg<%= first_arg %>;
    if ( argc > <%= first_arg %> )
    {
        if ( argv[<%= first_arg %>].isString() )
        {
            arg<%= first_arg %> = convertToStringW(argv[<%= first_arg %>].getString());
<% if first_arg == 0 %>
            oRes.setStringParam(argv[<%= first_arg %>].getString());
<% end %>
        }
        else if (!argv[<%= first_arg %>].isNull())
        {
            oRes.setArgError(L"Type error: argument " L<%= "\"#{first_arg}\"" %> L" should be " L<%= "\"#{param.type.downcase}\"" %> );
            return oRes.toJSON();
        }
    }
<% end %>

<% if param.type == MethodParam::TYPE_ARRAY %>
    <%= api_generator_cpp_makeNativeType(param.type) %> arg<%= first_arg %>;
    if ( argc > <%= first_arg %> )
    {
        if ( argv[<%= first_arg %>].isArray() )
        {
            CJSONArray arParam(argv[<%= first_arg %>]);
            for( int i = 0; i < arParam.getSize(); i++ )
            {
                arg<%= first_arg %>.addElement( convertToStringW(arParam[i].getString()) );
            }
        }
        else if (!argv[<%= first_arg %>].isNull())
        {
            oRes.setArgError(L"Type error: argument " L<%= "\"#{first_arg}\"" %> L" should be " L<%= "\"#{param.type.downcase}\"" %> );
            return oRes.toJSON();
        }
    }
<% end %>

<% if param.type == MethodParam::TYPE_HASH %>
    <%= api_generator_cpp_makeNativeType(param.type) %> arg<%= first_arg %>;
    if ( argc > <%= first_arg %> )
    {
        if ( argv[<%= first_arg %>].isObject() )
        {
            CJSONStructIterator objIter(argv[<%= first_arg %>]);

            for( ; !objIter.isEnd(); objIter.next() )
            {
                arg<%= first_arg %>[convertToStringW(objIter.getCurKey())] = convertToStringW(objIter.getCurString());
            }
        }
        else if (!argv[<%= first_arg %>].isNull())
        {
            oRes.setArgError(L"Type error: argument " L<%= "\"#{first_arg}\"" %> L" should be " L<%= "\"#{param.type.downcase}\"" %> );
            return oRes.toJSON();
        }
    }
<% end %>
        
<% functor_params += "arg#{first_arg}, " %>
<% first_arg = first_arg+1 %>
<% end %>

    if ( argc > nCallbackArg )
    {
<% if module_method.has_callback == ModuleMethod::CALLBACK_NONE %>
        oRes.setArgError(L"Wrong number of arguments: " + convertToStringW(argc) + L" instead of " + convertToStringW(<%= module_method.params.size() %>) );
        return oRes.toJSON();
<% end %>
        
        if ( !argv[nCallbackArg].isString() )
        {
            oRes.setArgError(L"Type error: callback should be String");
            return oRes.toJSON();
        }

        oRes.setCallInUIThread(<%= module_method.is_run_in_ui_thread ? "true" : "false" %>);
        oRes.setRubyCallback( argv[nCallbackArg].getString() );
        if ( argc > nCallbackArg + 1 )
        {
            if ( !argv[nCallbackArg + 1].isString() )
            {
                oRes.setArgError(L"Type error: callback parameter should be String");
                return oRes.toJSON();
            }

            oRes.setCallbackParam( argv[nCallbackArg + 1].getString() );
        }
        
    }

<% if module_method.access != ModuleMethod::ACCESS_STATIC %>
    pFunctor = rho_makeInstanceClassFunctor<%= module_method.params.size()+1%>( pObj, &I<%= $cur_module.name %>::<%= module_method.name %>, <%= functor_params %> oRes );
<% else %>
    pFunctor = rho_makeInstanceClassFunctor<%= module_method.params.size()+1%>( C<%= $cur_module.name %>FactoryBase::get<%= $cur_module.name %>SingletonS(), &I<%= $cur_module.name %>Singleton::<%= module_method.name %>, <%= functor_params %> oRes );
<% end %>

<% if module_method.is_run_in_ui_thread %>
    rho_wm_impl_performOnUiThread( pFunctor );
<% elsif module_method.is_run_in_thread %>
    C<%= $cur_module.name %>FactoryBase::get<%= $cur_module.name %>SingletonS()->addCommandToQueue( pFunctor );
<% else %>

    if ( bUseCallback )
        C<%= $cur_module.name %>FactoryBase::get<%= $cur_module.name %>SingletonS()->addCommandToQueue( pFunctor );
    else
    {
        delete pFunctor;

<% if module_method.access != ModuleMethod::ACCESS_STATIC %>
        pObj-><%= module_method.name %>( <%= functor_params %> oRes );
<% else %>
        C<%= $cur_module.name %>FactoryBase::get<%= $cur_module.name %>SingletonS()-><%= module_method.name %>( <%= functor_params %> oRes );
<% end %>

    }
<% end %>

    return oRes.toJSON();

}

<% end %>

